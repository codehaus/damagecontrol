require 'test/unit'
require 'damagecontrol/cruisecontrol/CruiseControlBridge'

module DamageControl

	class CruiseControlBridgeTest < Test::Unit::TestCase
		def test_call_cc_bridge_with_fake_source_control
			bridge = CruiseControlBridge.new
			bridge.sourcecontrol = "damagecontrol.FakeSourceControl"
			bridge.parameters = { "type" => "ruby_type" }
			now = Time.now
			modification = bridge.modifications(now, now)[0]
			assert_equal("-ruby_type", modification.type) # TODO this is actually wrong!
			assert_equal(now.to_s, modification.modified_time.to_s)
			assert_equal("revision", modification.revision)
			assert_equal("comment", modification.comment)
			assert_equal("emailAddress", modification.email_address)
			assert_equal("fileName", modification.file_name)
			assert_equal("folderName", modification.folder_name)
		end
	end

end
