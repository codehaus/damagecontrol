require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/xmlrpc/Trigger'

module DamageControl
module XMLRPC

  class TriggerTest < Test::Unit::TestCase
    include MockIt
    
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
      project_config_repository = new_mock
      t = Trigger.new(
        ::XMLRPC::WEBrickServlet.new,
        hub, 
        project_config_repository,
        "foo"
      )

      project_config_repository.__expect(:create_build) do |project_name| 
        assert_equal("damagecontrol", project_name)
        Build.new(project_name)
      end

      hub.__expect(:put) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert_equal("damagecontrol", message.build.project_name)
      end

      val = t.request("damagecontrol")
      assert(val)
      
    end
    
    def test_unix_trigger_url
      ENV['WINDIR'] = nil
      ENV['windir'] = nil
      expected = "/some/where/bin/requestbuild --url http://builds.codehaus.org/damagecontrol/private/xmlrpc --projectname jalla"
      assert_equal(expected, Trigger.trigger_command("/some/where", "jalla", "http://builds.codehaus.org/damagecontrol/private/xmlrpc"))
    end
    
    def test_win_trigger_url
      ENV['windir'] = "blah"
      expected = "C:\\somewhere\\bin\\requestbuild --url http://builds.codehaus.org/damagecontrol/private/xmlrpc --projectname jalla"
      assert_equal(expected, Trigger.trigger_command("C:\\somewhere", "jalla", "http://builds.codehaus.org/damagecontrol/private/xmlrpc"))
    end
  end

end
end
