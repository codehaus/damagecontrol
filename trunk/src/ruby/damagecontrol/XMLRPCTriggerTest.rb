require 'test/unit' 
require 'mockit' 
require 'xmlrpc/server' 
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/XMLRPCTrigger'
require 'damagecontrol/FileUtils'

module DamageControl

  class XMLRPCTriggerTest < Test::Unit::TestCase
    
    include HubTestHelper
    include DamageControl::FileUtils

    def setup
      create_hub
    end

    def test_adds_handler_for_build_request
      rpc_servlet = MockIt::Mock.new
      rpc_servlet.__expect(:add_handler) do |interface, object|
        assert_equal(XMLRPCTrigger::INTERFACE, interface)
        assert(object.is_a?(XMLRPCTrigger))
      end
      XMLRPCTrigger.new(rpc_servlet, hub, "#{damagecontrol_home}/target/temp_xmlrpctrigger_#{Time.new.to_i}")
      rpc_servlet.__verify
    end

    def test_call_on_request_requests_build
      t = XMLRPCTrigger.new(XMLRPC::WEBrickServlet.new, hub, "#{damagecontrol_home}/target/temp_xmlrpctrigger_#{Time.new.to_i}")
      val = t.request("project_name: damagecontrol")
      assert(!val.nil?)
      assert_message_types_from_hub([BuildRequestEvent])
      assert(!messages_from_hub[0].build.nil?)
      assert_equal("damagecontrol", messages_from_hub[0].build.project_name)
    end

    def test_call_on_request_build_requests_build
      expected = <<-EOF
---
scm_spec: scm_spec
build_command_line: build_command_line
project_name: project_name
nag_email: nag_email
...
      EOF

      mock_file = MockIt::Mock.new
      mock_file.__expect(:read) {
        expected
      }

      t = XMLRPCTrigger.new(XMLRPC::WEBrickServlet.new, hub, "#{damagecontrol_home}/target/temp_xmlrpctrigger_#{Time.new.to_i}")
      def t.set_mock_file(mock_file)
        @mock_file = mock_file
      end
      def t.project_file(project_name)
        @mock_file
      end
      t.set_mock_file(mock_file)
      
      val = t.request_build("project_name", "2004-04-15T18:05:47")
      assert(!val.nil?)
      assert_message_types_from_hub([BuildRequestEvent])
      assert(!messages_from_hub[0].build.nil?)
      assert_equal("project_name", messages_from_hub[0].build.project_name)
    end

  end

end
