require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/publisher/JabberPublisher'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/template/ShortTextTemplate'

module DamageControl

  class JabberPublisherTest < Test::Unit::TestCase
  
    def setup
      @jabber_mock = Mock.new
      b = Build.new("project_name")
      b.status = Build::SUCCESSFUL
      @build_complete_event = BuildCompleteEvent.new(b)
    end
    
    def test_not_sending_message_to_empty_recipients_list_on_build_complete
      @publisher = JabberPublisher.new(Hub.new, "username", "password", emptyRecipientList = [], ShortTextTemplate.new)
      @publisher.jabber = @jabber_mock
    
      @publisher.process_message(@build_complete_event)
      
      @jabber_mock.__verify
    end

    def test_sends_message_to_multiple_recipients_list_on_build_complete
      @publisher = JabberPublisher.new(Hub.new, "username", "password", recipientList = ["recipient1","recipient2"], ShortTextTemplate.new)
      @publisher.jabber = @jabber_mock
  
      @jabber_mock.__next(:send_message_to_recipient) { |recipient, message|
        assert_equal("recipient1", recipient)
        assert_equal("[project_name] BUILD SUCCESSFUL ", message)
      }
    
      @jabber_mock.__next(:send_message_to_recipient) { |recipient, message| 
        assert_equal("recipient2", recipient)
        assert_equal("[project_name] BUILD SUCCESSFUL ", message)
      }
      
      @publisher.process_message(@build_complete_event)
      
      @jabber_mock.__verify
    end

  end
end
