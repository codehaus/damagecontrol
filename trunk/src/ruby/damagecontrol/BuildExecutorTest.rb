require 'test/unit'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/Build'
require 'damagecontrol/HubTestHelper'

module DamageControl

	class BuilderExecutorTest < Test::Unit::TestCase
	
		include HubTestHelper
	
		def setup
			create_hub
			@builder = BuildExecutor.new(hub)
			@build = Build.new("Aslak", nil, nil)
			@build.build_command_line = "echo Hello Aslak!"
		end
	
		def test_executes_process_and_sends_build_complete_on_build_request
			hub.publish_message(BuildRequestEvent.new(@build))
			assert_message_types("DamageControl::BuildRequestEvent DamageControl::BuildProgressEvent DamageControl::BuildCompleteEvent")
			assert_equal(BuildProgressEvent.new(@build, "Hello Aslak!\n"), messages_from_hub[1])
			assert_equal("Hello Aslak!\n", messages_from_hub[1].output)
			assert_equal(BuildCompleteEvent.new(@build), messages_from_hub[2])
		end
		
		def test_doesnt_do_anything_on_other_events
			@builder.receive_message(nil)
			assert_equal(nil, hub.last_message)
		end
		
	end
		
end