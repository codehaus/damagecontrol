require 'test/unit'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/CruiseControlLogPoller'
require 'rexml/document'

module DamageControl
	class CruiseControlLogPollerTest < Test::Unit::TestCase
		
		include HubTestHelper
		include FileUtils
		include REXML
	
		def test_new_log_sends_build_complete_event
			create_hub
			@ccpoller = CruiseControlLogPoller.new(@hub, ".")
			@ccpoller.new_file(damagecontrol_file("testdata/log20030929145347.xml"))
			assert_message_types("DamageControl::BuildCompleteEvent")
			assert_equal('dxbranch', messages[0].project.name)
			assert_equal('build.698', messages[0].build.label)
		end
		
		def test_parse_log_file
		end
	end
end