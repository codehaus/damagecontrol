require 'test/unit'
require 'mockit'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'
require 'damagecontrol/template/MockTemplate'

module DamageControl

  class IRCPublisherTest < Test::Unit::TestCase
  
    def setup
      @mock_template = MockTemplate.new
      @publisher = IRCPublisher.new(Hub.new, "server", "channel", @mock_template)
      @irc_mock = MockIt::Mock.new
      @publisher.irc = @irc_mock
    end
    
    def setup_irc_connected
      @irc_mock.__setup(:connected?) { true }
      @irc_mock.__setup(:in_channel?) { true }
    end
    
    def teardown
      @irc_mock.__verify
    end
    
    def test_sends_message_on_build_complete
      setup_irc_connected
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal(message, @mock_template.generate(nil))}
      
      evt = BuildCompleteEvent.new(nil)
      @publisher.enq_message(evt)
      @publisher.process_messages
      
      assert(@publisher.consumed_message?(evt))
    end
    
    def test_sends_message_on_build_complete
      setup_irc_connected
      @irc_mock.__expect(:send_message_to_channel) {|message| 
        assert_equal(message, "BUILD STARTED project") }
      
      evt = BuildStartedEvent.new(Build.new("project"))
      @publisher.enq_message(evt)
      @publisher.process_messages
      
      assert(@publisher.consumed_message?(evt))
    end

  end
end
