require 'test/unit'
require 'mockit'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/Hub'
require 'damagecontrol/publisher/EmailPublisher'
require 'damagecontrol/template/ShortTextTemplate'
require 'ftools'

module DamageControl

  class EmailPublisherTest < Test::Unit::TestCase
  
    def setup
      @subject_template = ShortTextTemplate.new
      @body_template = ShortTextTemplate.new
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
      build.status = Build::FAILED

      @email_publisher.process_message(BuildCompleteEvent.new(build))
      assert_equal("[project_name] BUILD FAILED  [project_name] BUILD FAILED  noreply@somewhere.foo somelist@someproject.bar", @email_publisher.mail_content)
    end
    
    def test_nothing_is_sent_unless_build_complete_event
      @email_publisher.process_message(nil)
      assert_nil(@email_publisher.mail_content)
    end
    
  end
end
