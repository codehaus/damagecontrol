require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/publisher/EmailPublisher'
require 'damagecontrol/template/ShortTextTemplate'
require 'ftools'

module DamageControl

  class DcServerStub
    def dc_url
      "http://moradi.com/"
    end
  end

  class EmailPublisherTest < Test::Unit::TestCase
  
    def setup
      @email_publisher = EmailPublisher.new(Hub.new, DcServerStub.new, "short_text_build_result.erb", "short_html_build_result.erb", "noreply@somewhere.foo")

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
      build.timestamp = Time.utc(1971,2,28,23,45,0,0)

      @email_publisher.process_message(BuildCompleteEvent.new(build))
      assert_equal("[cheese] BUILD FAILED: http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500|<a href=\"http://moradi.com/public/project?project_name=cheese\">[cheese] BUILD FAILED</a>|noreply@somewhere.foo|somelist@someproject.bar", @email_publisher.mail_content)
    end
    
    def test_nothing_is_sent_unless_build_complete_event
      @email_publisher.process_message(nil)
      assert_nil(@email_publisher.mail_content)
    end
    
  end
end
