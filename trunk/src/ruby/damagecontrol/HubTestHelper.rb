require 'damagecontrol/Hub'

module DamageControl

	module HubTestHelper
		attr_reader :hub
		attr_reader :messages

		def create_hub
			@hub = Hub.new
			@hub.add_subscriber(self)
			@messages = Array.new
		end
		
		def receive_message (message)
			@messages<<message
		end
		
		def message_types
			@messages.collect{|message| message.class}.join(" ")
		end
		
		def assert_message_types (expected)
			assert_equal(expected, message_types)
		end
	end
	
end