require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/xmlrpc/Trigger'

module DamageControl
module XMLRPC

  class TriggerTest < Test::Unit::TestCase
    
    def test_adds_handler_for_build_request
      rpc_servlet = MockIt::Mock.new
      rpc_servlet.__expect(:add_handler) do |interface, object|
        assert_equal(Trigger::INTERFACE, interface)
        assert(object.is_a?(Trigger))
      end

      Trigger.new(rpc_servlet, MockIt::Mock.new, nil)
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
      hub = MockIt::Mock.new
      t = Trigger.new(::XMLRPC::WEBrickServlet.new, hub, project_configuration_repository)

      hub.__expect(:publish_message) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert(!message.build.nil?)
        assert_equal("damagecontrol", message.build.project_name)
        assert_equal("20040615120000", message.build.timestamp)
      end

      val = t.trig("damagecontrol", timestamp)
      assert(!val.nil?)
      
      hub.__verify
    end

  end

end
end
