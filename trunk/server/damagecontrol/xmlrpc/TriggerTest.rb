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
        new_mock,
        "foo"
      )
    end

    def test_call_on_trig_requests_a_build
      project_configuration_repository = new_mock.__setup(:create_build) do |project_name, actual_timestamp|
        assert_equal("damagecontrol", project_name)
        Build.new(project_name)
      end
      hub = new_mock
      t = Trigger.new(
        ::XMLRPC::WEBrickServlet.new,
        hub, 
        project_configuration_repository,
        new_mock.__expect(:checkout) {},
        "foo"
      )

      hub.__expect(:publish_message) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert(message.build)
        assert_equal("damagecontrol", message.build.project_name)
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
