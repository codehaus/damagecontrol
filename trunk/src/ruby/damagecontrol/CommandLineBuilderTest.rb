require 'damagecontrol/Hub'
require 'damagecontrol/CommandLineBuilder'
require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/BuildCompleteEvent'

module DamageControl

	class CommandLineBuilderTest < Test::Unit::TestCase
	
		def setup
			@hub = Hub.new
			@b = CommandLineBuilder.new(@hub, "echo Hello Aslak!")
		end
	
		def test_executes_process_and_sends_build_complete_on_receive_build_request
			@b.receive_message(BuildRequestEvent.new())
			assert_equal(BuildCompleteEvent.new("Hello Aslak!\n"), @hub.last_message)
			assert_equal("Hello Aslak!\n", @hub.last_message.result)
		end
		
		def test_doesnt_do_anything_on_other_events
			@b.receive_message(nil)
			assert_equal(nil, @hub.last_message)
		end
		
	end
		
end