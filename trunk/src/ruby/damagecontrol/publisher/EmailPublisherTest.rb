require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/Hub'
require 'damagecontrol/publisher/EmailPublisher'
require 'damagecontrol/template/MockTemplate'
require 'ftools'

module DamageControl

  class EmailPublisherTest < Test::Unit::TestCase
  
    def setup
      @subject_template = Mock.new
      @body_template = Mock.new
      @email_publisher = EmailPublisher.new(Hub.new, @subject_template, @body_template, "noreply@somewhere.foo")

      def @email_publisher.sendmail(subject, body, from, to)
        @mail_content = "#{subject} #{body} #{from} #{to}"
      end
      
      def @email_publisher.mail_content
        @mail_content
      end
    end
  
    def test_email_is_sent_upon_build_complete_event    
      build = Build.new("project_name", {"nag_email" => "somelist@someproject.bar"})

      @body_template.__return(:file_type, "email")
      @body_template.__next(:generate) { |build2|
        "some_body"
      }
      @subject_template.__return(:file_type, "email")
      @subject_template.__next(:generate) { |build2|
        "some_subject"
      }
      
      @email_publisher.process_message(BuildCompleteEvent.new(build))
      assert_equal("some_subject some_body noreply@somewhere.foo somelist@someproject.bar", @email_publisher.mail_content)

      @subject_template.__verify
      @body_template.__verify
    end
    
    def test_nothing_is_sent_unless_build_complete_event
      @email_publisher.process_message(nil)
      assert_nil(@email_publisher.mail_content)
    end
    
  end
end
