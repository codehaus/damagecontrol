require 'test/unit'
require 'pebbles/mockit'
require 'pebbles/Space'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/publisher/EmailPublisher'
require 'ftools'

module DamageControl

  class EmailPublisherTest < Test::Unit::TestCase
    include MockIt

    class FakeSender

      attr_accessor :server
      attr_accessor :mail
      attr_accessor :from
      attr_accessor :to

      def start(server)
        @server = server
        yield self
      end

      def sendmail(mail, from, to)
        @mail = mail
        @from = from
        @to = to
      end

    end
  
    def setup      
      @sender = FakeSender.new()
      @email_publisher = EmailPublisher.new(
        new_mock.__expect(:add_consumer),
        nil,
        :SubjectTemplate => "short_text_build_result.erb", 
        :BodyTemplate => "short_html_build_result.erb",
        :FromEmail => "noreply@somewhere.foo",
        :MailServerHost => "mail.somewhere.foo",
        :Sender => @sender)

    end
  
    def test_email_is_sent_upon_build_complete_event    
      build = Build.new("cheese", {"nag_email" => "somelist@someproject.bar"}, "http://moradi.com/public/")
      build.status = Build::FAILED
      build.dc_creation_time = Time.utc(1971,2,28,22,45,0,0)
      build.dc_start_time = Time.utc(1971,2,28,23,45,0,0)
      change1 = Change.new("a/file", "aslak", nil, nil, Time.new.utc)
      build.changesets.add(change1)

      @email_publisher.on_message(BuildCompleteEvent.new(build))
      assert_equal("mail.somewhere.foo", @sender.server)
      assert_equal("noreply@somewhere.foo", @sender.from)
      assert_equal(["somelist@someproject.bar"], @sender.to)
      assert_equal("To: somelist@someproject.bar\r\n" +
        "From: noreply@somewhere.foo\r\n" +
        "Date: Sun, 28 Feb 1971 23:45:00 +0000\r\n" + 
        "Subject: [cheese] BUILD FAILED\r\n" + 
        "MIME-Version: 1.0\r\nContent-Type: text/html\r\n" +
        "\r\n" + 
        "aslak broke the build <br>" +
        "<a href=\"http://moradi.com/public/project/cheese?dc_creation_time=19710228224500\">[cheese] BUILD FAILED</a>", 
        @sender.mail)
    end
    
    def test_nothing_is_sent_unless_build_complete_event
      @email_publisher.on_message(nil)
      assert_nil(@sender.mail)
    end
    
  end
end
