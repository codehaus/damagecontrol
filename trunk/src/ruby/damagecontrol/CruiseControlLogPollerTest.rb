require 'test/unit'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/CruiseControlLogPoller'
require 'rexml/document'

module DamageControl
	class CruiseControlLogPollerTest < Test::Unit::TestCase
		
		include HubTestHelper
		include FileUtils
		include REXML
		
		def setup
			@dir = "test#{Time.new.to_i}"
			mkdirs(@dir)
			create_hub
			@log_file = damagecontrol_file("testdata/log20030929145347.xml")
			@ccpoller = CruiseControlLogPoller.new(@hub, @dir)
		end
		
		def teardown
			rmdir(@dir)
		end
		
		def assert_no_messages
			assert(messages.empty?)
		end
	
		def test_new_log_sends_build_complete_event
			@ccpoller.force_tick
			assert_no_messages
			
			copy(@log_file, "#{@dir}/log.xml")
			@ccpoller.force_tick
			assert_message_types("DamageControl::BuildCompleteEvent")
			assert_equal('dxbranch', messages[0].project.name)
			assert_equal('build.698', messages[0].build.label)
		end
		
	end
end