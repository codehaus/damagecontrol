require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/publisher/JabberPublisher'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'
require 'damagecontrol/template/MockTemplate'

module DamageControl

  class JabberPublisherTest < Test::Unit::TestCase
  
    def setup
      @template_mock = MockTemplate.new
      @jabber_mock = Mock.new
      @build_complete_event = BuildCompleteEvent.new(Build.new("project_name"))
    end
    
    def test_not_sending_message_to_empty_recipients_list_on_build_complete
	  @publisher = JabberPublisher.new(Hub.new, "username", "password", emptyRecipientList = [], @template_mock)
      @publisher.jabber = @jabber_mock
	  
      @publisher.process_message(@build_complete_event)
      
      @jabber_mock.__verify
    end

    def test_sends_message_to_multiple_recipients_list_on_build_complete
	  @publisher = JabberPublisher.new(Hub.new, "username", "password", recipientList = ["recipient1","recipient2"], @template_mock)
      @publisher.jabber = @jabber_mock
	
      @jabber_mock.__next(:send_message_to_recipient) { |recipient, message|
			assert_equal("recipient1", recipient)
			assert_equal(@template_mock.generate(nil), message)
		}
		
      @jabber_mock.__next(:send_message_to_recipient) { |recipient, message| 
			assert_equal("recipient2", recipient)
			assert_equal(@template_mock.generate(nil), message)
		}
      
      @publisher.process_message(@build_complete_event)
      
      @jabber_mock.__verify
    end

  end
end
