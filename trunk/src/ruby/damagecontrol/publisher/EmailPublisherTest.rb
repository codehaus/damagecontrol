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
      @template = Mock.new
      @email_publisher = EmailPublisher.new(Hub.new, @template, "noreply@somewhere.foo")

      def @email_publisher.sendmail(content, from, to)
        @mail_content = "#{content} #{from} #{to}"
      end
      
      def @email_publisher.mail_content
        @mail_content
      end
    end
  
    def test_email_is_sent_upon_build_complete_event    
      build = Build.new("project_name", {"nag_email" => "somelist@someproject.bar"})

      @template.__return(:file_type, "email")
      @template.__next(:generate) { |build2|
        "some contentA"
      }
      
      @email_publisher.process_message(BuildCompleteEvent.new(build))
      assert_equal("some content noreply@somewhere.foo somelist@someproject.bar", @email_publisher.mail_content)

      @template.__verify
    end
    
    def test_nothing_is_sent_unless_build_complete_event
      @email_publisher.process_message(nil)
      assert_nil(@email_publisher.mail_content)
    end
    
  end
end
