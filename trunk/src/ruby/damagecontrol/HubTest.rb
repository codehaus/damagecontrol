require 'damagecontrol/Hub'

module DamageControl

	class HubTest < Test::Unit::TestCase
		def setup
			@hub = Hub.new
		end
	
		def test_published_message_returned_by_last_message
			assert_nil(@hub.last_message)
			@hub.publish_message("message")
			assert_equal("message", @hub.last_message)
		end
		
		def test_subscriber_receives_published_message
			@hub.add_subscriber(self)
			assert_nil(@received_message)
			@hub.publish_message("message")
			assert_equal("message", @received_message)
		end
		
		def receive_message(message)
			@received_message = message
		end
	end
	
	def InOutQueue
	end

	def InOutQueueTest
		def test_published_message_is_put_on_out_queue
		end
	end

end