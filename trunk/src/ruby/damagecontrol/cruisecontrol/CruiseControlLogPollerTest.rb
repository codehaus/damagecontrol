require 'test/unit'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/cruisecontrol/CruiseControlLogPoller'
require 'ftools'

module DamageControl
	class CruiseControlLogPollerTest < Test::Unit::TestCase
		
		include HubTestHelper
		include FileUtils
		include REXML
		
		def setup
			@dir = "test#{Time.new.to_i}"
			File.mkpath(@dir)
			create_hub
			@log_file = damagecontrol_file("../testdata/log20030929145347.xml")
			@ccpoller = CruiseControlLogPoller.new(@hub, @dir)
		end
		
		def teardown
			rmdir(@dir)
		end
		
		def test_new_log_sends_build_complete_event
			@ccpoller.force_tick
			assert_no_messages
			
			File.copy(@log_file, "#{@dir}/log.xml")
			@ccpoller.force_tick
			assert_message_types("DamageControl::BuildCompleteEvent")
			assert_equal('dxbranch', messages_from_hub[0].build.project_name)
			assert_equal('build.698', messages_from_hub[0].build.label)
			assert_equal(false, messages_from_hub[0].build.successful)
			assert_equal("BUILD FAILED detected", messages_from_hub[0].build.error_message)
		end
		
	end
end