require 'mock_with_returns'
require 'test/unit'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/IRCPublisher'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/FileUtils'

module DamageControl

	class IRCPublisherTest < Test::Unit::TestCase
	
		def setup
			@publisher = IRCPublisher.new(Hub.new, "server", "channel")
			@irc_mock = Mock.new
			@publisher.irc = @irc_mock
			@event = BuildCompleteEvent.new(Build.new("project"))
		end
		
		def test_sends_message_on_build_complete_if_connected_and_in_channel
			@irc_mock.__return(:connected?, true)
			@irc_mock.__return(:in_channel?, true)
			@irc_mock.__next(:send_message_to_channel) {|message| 
				assert(message.index("project")) }
			
			@publisher.enq_message(@event)
			@publisher.process_messages
			
			assert(@publisher.consumed_message?(@event))
			@irc_mock.__verify
		end
		
		def test_if_not_connected_connects_and_does_not_consume_message
			@irc_mock.__return(:connected?, false)
			@irc_mock.__return(:in_channel?, false)
			@irc_mock.__next(:connect) {|server, handle| 
				assert_equal(server, "server")
				assert_equal(handle, "dcontrol") }
			
			@publisher.enq_message(@event)
			@publisher.process_messages
			
			assert(!@publisher.consumed_message?(@event))
			@irc_mock.__verify
		end
		
		def test_if_not_in_channel_joins_channel_and_does_not_consume_message
			@irc_mock.__return(:connected?, true)
			@irc_mock.__return(:in_channel?, false)
			@irc_mock.__next(:join_channel) {|channel| 
				assert_equal(channel, "channel") }
			
			@publisher.enq_message(@event)
			@publisher.process_messages
			
			assert(!@publisher.consumed_message?(@event))
			@irc_mock.__verify
		end
		
	end
end