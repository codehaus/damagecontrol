require 'test/unit' 
require 'mockit' 
require 'xmlrpc/server' 
require 'damagecontrol/HubTestHelper'
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
      Trigger.new(rpc_servlet, hub)
      rpc_servlet.__verify
    end

    def test_call_on_request_requests_build
      t = Trigger.new(::XMLRPC::WEBrickServlet.new, hub)
      val = t.request("project_name: damagecontrol")
      assert(!val.nil?)
      assert_message_types_from_hub([BuildRequestEvent])
      assert(!messages_from_hub[0].build.nil?)
      assert_equal("damagecontrol", messages_from_hub[0].build.project_name)
    end

  end

end
end
