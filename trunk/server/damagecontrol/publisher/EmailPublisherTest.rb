require 'test/unit'
require 'pebbles/mockit'
require 'pebbles/Space'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/publisher/EmailPublisher'
require 'ftools'

module DamageControl

  class EmailPublisherTest < Test::Unit::TestCase
    include MockIt
  
    def setup
      @email_publisher = EmailPublisher.new(
        new_mock.__expect(:add_consumer),
        nil,
        :SubjectTemplate => "short_text_build_result.erb", 
        :BodyTemplate => "short_html_build_result.erb",
        :FromEmail => "noreply@somewhere.foo")

      def @email_publisher.sendmail(subject, body, from, to)
        @mail_content = "#{subject}|#{body}|#{from}|#{to}"
      end
      def @email_publisher.mail_content
        @mail_content
      end
    end
  
    def test_email_is_sent_upon_build_complete_event    
      build = Build.new("cheese", Time.now, {"nag_email" => "somelist@someproject.bar"})
      build.status = Build::FAILED
      build.url =  "http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500"
      build.timestamp = Time.utc(1971,2,28,23,45,0,0)

      @email_publisher.on_message(BuildCompleteEvent.new(build))
      assert_equal("[cheese] BUILD FAILED|<a href=\"http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500\">[cheese] BUILD FAILED</a>|noreply@somewhere.foo|somelist@someproject.bar", @email_publisher.mail_content)
    end
    
    def test_nothing_is_sent_unless_build_complete_event
      @email_publisher.on_message(nil)
      assert_nil(@email_publisher.mail_content)
    end
    
  end
end
