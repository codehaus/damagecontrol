require 'test/unit'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/CruiseControlLogPoller'

module DamageControl
	class CruiseControlLogPollerTest < Test::Unit::TestCase
		
		include HubTestHelper
	
		def test_new_log_sends_build_complete_event
			create_hub
			@ccpoller = CruiseControlLogPoller.new(".", @hub)
			@ccpoller.new_file("build4711.xml")
			assert_message_types("DamageControl::BuildCompleteEvent")
		end
	end
end