require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildResult'
require 'damagecontrol/FileUtils'
require 'damagecontrol/templates/MockTemplate'

module DamageControl

  class IRCPublisherTest < Test::Unit::TestCase
  
    def setup
      @mock_template = MockTemplate.new
      @publisher = IRCPublisher.new(Hub.new, "server", "channel", @mock_template)
      @irc_mock = Mock.new
      @publisher.irc = @irc_mock
      @event = BuildCompleteEvent.new(nil)
    end
    
    def test_sends_message_on_build_complete
      @irc_mock.__return(:connected?, true)
      @irc_mock.__return(:in_channel?, true)
      @irc_mock.__next(:send_message_to_channel) {|message| 
        assert_equal(message, @mock_template.generate(nil))}
      
      @publisher.enq_message(@event)
      @publisher.process_messages
      
      assert(@publisher.consumed_message?(@event))
      @irc_mock.__verify
    end

  end
end