require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/publisher/JabberPublisher'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class DcServerStub
    def dc_url
      "http://moradi.com/"
    end
  end

  class JabberPublisherTest < Test::Unit::TestCase
  
    def setup
      @jabber_mock = Mock.new
      b = Build.new("cheese")
      b.timestamp = Time.utc(1971,2,28,23,45,0,0)
      b.status = Build::SUCCESSFUL
      @build_complete_event = BuildCompleteEvent.new(b)
    end
    
    def test_not_sending_message_to_empty_recipients_list_on_build_complete
      @publisher = JabberPublisher.new(Hub.new, DcServerStub.new, "username", "password", emptyRecipientList = [], "short_html_build_result.erb")
      @publisher.jabber = @jabber_mock
    
      @publisher.process_message(@build_complete_event)
      
      @jabber_mock.__verify
    end

    def test_sends_message_to_multiple_recipients_list_on_build_complete
      @publisher = JabberPublisher.new(Hub.new, DcServerStub.new, "username", "password", recipientList = ["recipient1","recipient2"], "short_html_build_result.erb")
      @publisher.jabber = @jabber_mock
  
      expected = "<a href=\"http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500\">[cheese] BUILD SUCCESSFUL</a>"
      @jabber_mock.__next(:send_message_to_recipient) { |recipient, message|
        assert_equal("recipient1", recipient)
        assert_equal(expected, message)
      }
    
      @jabber_mock.__next(:send_message_to_recipient) { |recipient, message| 
        assert_equal("recipient2", recipient)
        assert_equal(expected, message)
      }
      
      @publisher.process_message(@build_complete_event)
      
      @jabber_mock.__verify
    end

  end
end
