require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/xmlrpc/Trigger'

module DamageControl
module XMLRPC

  class TriggerTest < Test::Unit::TestCase
    include MockIt
    include FileUtils
    
    def test_adds_handler_in_initialize
      rpc_servlet = new_mock
      rpc_servlet.__expect(:add_handler) do |interface, object|
        assert_equal(Trigger::INTERFACE, interface)
        assert(object.is_a?(Trigger))
      end

      Trigger.new(
        rpc_servlet, 
        new_mock,
        new_mock,
        "foo"
      )
    end

    def test_call_on_trig_requests_a_build
      hub = new_mock
      t = Trigger.new(
        ::XMLRPC::WEBrickServlet.new,
        hub, 
        new_mock,
        "foo"
      )

      hub.__expect(:put) do |message|
        assert(message.is_a?(DoCheckoutEvent))
        assert(message.force_build)
        assert_equal("damagecontrol", message.project_name)
      end

      val = t.request("damagecontrol")
      assert(val)
      
    end
    
    def test_trigger_url
      expected = "sh #{damagecontrol_home}/bin/requestbuild --url http://builds.codehaus.org/damagecontrol/private/xmlrpc --projectname jalla"
      assert_equal(expected, Trigger.trigger_command(damagecontrol_home, "jalla", "http://builds.codehaus.org/damagecontrol/private/xmlrpc"))
    end

  end

end
end
