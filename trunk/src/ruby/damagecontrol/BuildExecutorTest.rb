require 'test/unit'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Project'

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
	
	class BuilderExecutorTest < Test::Unit::TestCase
	
		include HubTestHelper
	
		def setup
			create_hub
			@builder = BuildExecutor.new(hub)
			@project = Project.new("Aslak")
			@project.build_command_line = "echo Hello Aslak!"
		end
	
		def test_executes_process_and_sends_build_complete_on_build_request
			hub.publish_message(BuildRequestEvent.new(@project))
			assert_message_types("DamageControl::BuildRequestEvent DamageControl::BuildProgressEvent DamageControl::BuildCompleteEvent")
			assert_equal(BuildProgressEvent.new(@project, "Hello Aslak!\n"), messages[1])
			assert_equal("Hello Aslak!\n", messages[1].output)
			assert_equal(BuildCompleteEvent.new(@project), messages[2])
		end
		
		def test_doesnt_do_anything_on_other_events
			@builder.receive_message(nil)
			assert_equal(nil, hub.last_message)
		end
		
	end
		
end