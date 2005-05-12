require 'test/unit'
require 'damagecontrol/publisher/base'
require 'damagecontrol/publisher/fixture'

module DamageControl
  module Publisher
    class EmailTest < Test::Unit::TestCase
      include Fixture
  
      def test_should_send_email_with_sendmail_on_publish
        #verify_email(Sendmail.new)
      end
  
      def test_should_send_email_with_smtp_on_publish
        smtp = Smtp.new
        smtp.port = 2005
        verify_email(smtp)
      end
  
      def verify_email(publisher)
        BuildMailer.template_root = File.expand_path(File.dirname(__FILE__) + "/../../../app/views")
        tmail = BuildMailer.create_email(mock_build(true), publisher)
        body = tmail.body_port.ropen.read
        assert(body.index("Successful build (by aslak)"))
        assert(body.index("path/seven"))
        to = ENV["DC_EMAIL_TEST"]
        if(to)
          publisher.to = to
          puts "Sending mail to #{to} (for real)"
          BuildMailer.deliver_email(mock_build(true), publisher)
        end
      end
    end
  end
end