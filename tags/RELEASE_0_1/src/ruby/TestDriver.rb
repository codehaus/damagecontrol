require 'ftools'
require 'damagecontrol/scm/CVS'
require 'test/unit/assertions'

include DamageControl

class TestDriver

  include Test::Unit::Assertions

  attr_reader :basedir
  attr_reader :cvs
  
  def initialize
    @basedir = File.expand_path("../../target/acceptance_#{Time.now.to_i}")
    @cvs = CVS.new
    File.mkpath(basedir)
    Dir.chdir(basedir)
  end

  def check_out_cvs_project(scm_spec, cvs_module)
    cvs.checkout("#{scm_spec}:#{cvs_module}", basedir) {|progress| puts progress}
    Dir.chdir(basedir)
  end
  
  def create_file(file, content)
    File.mkpath(File.dirname(file))
    File.open(file, "w") { |io| io.print(content) }
  end
  
  def commit_cvs_project(project, message)
    cvs.commit(project, message) {|progress| puts progress}
  end

  def send_email(host, user, password, mail)
    require 'net/smtp'
    assert(mail =~ /^From: (.*)$/, "from address not specified")
    from = $1
    assert(mail =~ /^To: (.*)$/, "to address not specified")
    to = $1
    Net::SMTP.start(host, 25, host, user, password, :plain) do |s|
      s.sendmail(mail, from, to)
    end
  end

  def check_for_email(host, user, password, mail)
    require 'net/pop'
    Net::POP3.new(host).start(user, password) do |p|
      assert(!p.mails.empty?, "no mails")
      p.mails.each do |incoming_mail| 
        if mail_matches?(mail, incoming_mail.pop)
          incoming_mail.delete
          return true
        end
      end
      assert(false, "no matching mail found")
    end
  end

  def mail_matches?(expected_mail, incoming_mail)
    mail_text = remove_all_but_subject_and_body(incoming_mail)
    if expected_mail != mail_text
      puts "mails do not match:"
      p mail_text
      puts "++++++"
      p expected_mail
      false
    else
      true
    end
  end

  def remove_all_but_subject_and_body(mail)
    mail.gsub!(/\r/, '')
    assert(mail =~ /^Subject: (.*)$/, "email has no subject #{mail}")
    subject = $1
    assert(mail =~/$^(.*)\Z/m, "email has no body #{mail}")
    body = $1
    %{Subject: #{subject}
#{body}}
  end
         
end

require 'test/unit'

class TestDriverTest < Test::Unit::TestCase
  
  def test_mail_matches_ignores_anything_but_subject_and_body
    assert(TestDriver.new.mail_matches?(EXPECTED_MAIL, INCOMING_MAIL))
  end

  def test_remove_everythig_but_subject_and_body
    assert_equal(%{Subject: test subject

test body
}, TestDriver.new.remove_all_but_subject_and_body(INCOMING_MAIL))
  end


EXPECTED_MAIL =
<<-EOF
Subject: test subject

test body
EOF

INCOMING_MAIL =
<<-EOF
To: blabla
Subject: test subject
From: blabla

test body
EOF

end
