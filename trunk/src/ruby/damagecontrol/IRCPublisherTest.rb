require 'mock'
require 'test/unit'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/BuildCompleteEvent'
require 'damagecontrol/IRCPublisher'
require 'damagecontrol/HubTestHelper'

module DamageControl

	class AsyncComponentTest < Test::Unit::TestCase
			
		class NonConsumingAsyncComponent < AsyncComponent
			attr_reader :processed_messages
			
			def initialize(hub)
				super(hub)
				@processed_messages = []
			end
			
			def process_message(message)
				processed_messages<<message
			end
		end
		
		class ConsumingAsyncComponent < NonConsumingAsyncComponent
			def process_message(message)
				super(message)
				consume_message(message)
			end
		end

		include HubTestHelper
		
		def setup
			create_hub
			@messages = [1, 2, 3]
		end

		def test_enqueued_message_processed_on_tick
			comp = NonConsumingAsyncComponent.new(hub)
			@messages.each {|message|
				@hub.publish_message(message)
			}
			comp.force_tick
			assert_equal(@messages, comp.processed_messages)
		end
		
		def test_non_consumed_messages_processed_again_on_next_tick
			comp = NonConsumingAsyncComponent.new(hub)
			@messages.each {|message|
				hub.publish_message(message)
			}
			comp.force_tick
			assert_equal(@messages, comp.processed_messages)
			@messages.each {|message|
				assert(!comp.consumed_message?(message))
			}
			comp.force_tick
			assert_equal(@messages + @messages, comp.processed_messages)
		end
		

		def test_consumed_message_not_processed_on_next_tick
			comp = ConsumingAsyncComponent.new(hub)
			@messages.each {|message|
				@hub.publish_message(message)
			}
			comp.force_tick
			assert_equal(@messages, comp.processed_messages)
			@messages.each {|message|
				assert(comp.consumed_message?(message))
			}
		end
	end

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
			@irc_mock.__next(:connect) {|server| assert_equal(server, "server") }
			
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