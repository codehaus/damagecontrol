$:<<'../../lib'

require 'test/unit' 
require 'mockit' 
require 'xmlrpc/server' 
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/publisher/XMLRPCStatusPublisher'

module DamageControl

  class XMLRPCStatusPublisherTest < Test::Unit::TestCase
    
    include HubTestHelper

    def setup
      create_hub
      @executor = BuildExecutor.new(hub)
      @scheduler = BuildScheduler.new(hub)
      @scheduler.default_quiet_period = 0
      @scheduler.add_executor(@executor)
      @build = Build.new("test", {"build_command_line" => "echo Hello"})
    end

    def test_adds_handler_for_status_request
      rpc_servlet = MockIt::Mock.new
      rpc_servlet.__expect(:add_handler) do |interface, object|
        assert_equal(XMLRPCStatusPublisher::INTERFACE, interface)
        assert(object.is_a?(XMLRPCStatusPublisher))
      end
      XMLRPCStatusPublisher.new(rpc_servlet, hub)
      rpc_servlet.__verify
    end
    
    def test_status_for_unknown_build
      t = XMLRPCStatusPublisher.new(XMLRPC::WEBrickServlet.new, hub)
      val = t.status("unknown_project_name")
      assert_equal("Unknown", val);
    end

    def test_request_build_updates_status
      t = XMLRPCStatusPublisher.new(XMLRPC::WEBrickServlet.new, hub)
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      val = t.status(@build.project_name)
      assert_equal("Scheduled", val);
    end

    def test_execute_build_updates_status
      t = XMLRPCStatusPublisher.new(XMLRPC::WEBrickServlet.new, hub)
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      @executor.process_next_scheduled_build
      val = t.status(@build.project_name)
      assert_match(val, /Built.*/);
    end

  end

end
