require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/xmlrpc/Trigger'

module DamageControl
module XMLRPC

  class TriggerTest < Test::Unit::TestCase
    
    include HubTestHelper

    def setup
      create_hub
    end

    def test_adds_handler_for_build_request
      rpc_servlet = MockIt::Mock.new
      rpc_servlet.__expect(:add_handler) do |interface, object|
        assert_equal(Trigger::INTERFACE, interface)
        assert(object.is_a?(Trigger))
      end
      Trigger.new(rpc_servlet, hub, nil)
      rpc_servlet.__verify
    end

    def test_call_on_trig_requests_a_build
      timestamp = Build.format_timestamp(Time.utc(2004, 06, 15, 12, 00, 00))
      project_configuration_repository = MockIt::Mock.new
      project_configuration_repository.__setup(:create_build) do |project_name, actual_timestamp|
        assert_equal("damagecontrol", project_name)
        assert_equal(timestamp, actual_timestamp)
        Build.new(project_name, timestamp)
      end
      t = Trigger.new(::XMLRPC::WEBrickServlet.new, hub, project_configuration_repository)
      val = t.trig("damagecontrol", timestamp)
      assert(!val.nil?)
      assert_message_types_from_hub([BuildRequestEvent])
      assert(!messages_from_hub[0].build.nil?)
      assert_equal("damagecontrol", messages_from_hub[0].build.project_name)
      assert_equal("20040615120000", messages_from_hub[0].build.timestamp)
    end

  end

end
end
