require 'damagecontrol/Hub'

module DamageControl

	module HubTestHelper
		attr_reader :hub
		attr_reader :messages_from_hub

		def create_hub
			@hub = Hub.new
			@hub.add_subscriber(self)
			@messages_from_hub = []
		end
				
		def receive_message (message)
			@messages_from_hub<<message
		end
		
		def message_types
			@messages_from_hub.collect{|message| message.class}.join(" ")
		end
		
		def assert_message_types (expected)
			assert_equal(expected, message_types)
		end

		def assert_no_messages
			assert(messages_from_hub.empty?)
		end
	end
	
end