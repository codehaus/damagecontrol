require 'test/unit'
require 'pebbles/mockit'
require 'pebbles/Space'
require 'damagecontrol/publisher/JabberPublisher'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class JabberPublisherTest < Test::Unit::TestCase
    include MockIt
  
    def setup
      @jabber_mock = new_mock
      b = Build.new("cheese")
      b.timestamp = Time.utc(1971,2,28,23,45,0,0)
      b.status = Build::SUCCESSFUL
      b.url = "http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500"
      @build_complete_event = BuildCompleteEvent.new(b)
    end
    
    def test_not_sending_message_to_empty_recipients_list_on_build_complete
      @publisher = JabberPublisher.new(
        new_mock.__expect(:add_consumer), 
        "username", 
        "password", 
        emptyRecipientList = [], 
        "short_html_build_result.erb"
      )
      @publisher.jabber = @jabber_mock
    
      @publisher.on_message(@build_complete_event)
    end

    def test_sends_message_to_multiple_recipients_list_on_build_complete
      @publisher = JabberPublisher.new(
        new_mock.__expect(:add_consumer), 
        "username", 
        "password", 
        recipientList = ["recipient1","recipient2"], 
        "short_html_build_result.erb"
      )
      @publisher.jabber = @jabber_mock
  
      expected = "<a href=\"http://moradi.com/public/project?action=build_details&project_name=cheese&timestamp=19710228234500\">[cheese] BUILD SUCCESSFUL</a>"
      @jabber_mock.__expect(:send_message_to_recipient) { |recipient, message|
        assert_equal("recipient1", recipient)
        assert_equal(expected, message)
      }
    
      @jabber_mock.__expect(:send_message_to_recipient) { |recipient, message| 
        assert_equal("recipient2", recipient)
        assert_equal(expected, message)
      }
      
      @publisher.on_message(@build_complete_event)
    end

  end
end
