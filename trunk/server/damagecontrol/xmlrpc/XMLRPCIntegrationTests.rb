require 'test/unit'
require 'net/http'
require 'pebbles/mockit'
require 'xmlrpc/client'
require 'damagecontrol/DamageControlServer'
require 'damagecontrol/scm/CVS'

module DamageControl

  # Needed because XMLRPC b0rks out all the time
  class XMLRPCIntegrationTests < Test::Unit::TestCase
    include FileUtils
  
    def setup
      @server = DamageControlServer.new(
        :RootDir => new_temp_dir,
        :HttpPort => 14712
      )
      @server.start
      @server.project_config_repository.new_project("myproject")
      project_config = @server.project_config_repository.default_project_config
      project_config["build_command_line"] = "echo hello"
      project_config["quiet_period"] = 0
      @server.project_config_repository.modify_project_config("myproject", project_config)
      sleep 5
    end

    def teardown
      @server.shutdown
    end
    
  def wait_for(timeout=60)
    0.upto(timeout) do
      return if yield
      sleep 1
    end
  end
    
    def test_request_build_and_checks_for_status
      begin
        client = ::XMLRPC::Client.new2("http://localhost:14712/private/xmlrpc")
        build = client.proxy("build")
        result = build.trig("myproject", Time.now.utc.strftime("%Y%m%d%H%M%S"))
        assert_not_nil(result)
        status = client.proxy("status")
        wait_for { !status.project_names.empty? }
        assert_equal(["myproject"], status.project_names)
        wait_for { status.last_completed_build("myproject") }
        build = status.last_completed_build("myproject")
        assert_not_nil(build)
        assert_equal("myproject", build.project_name)
      rescue ::XMLRPC::FaultException => e
        puts "Error:"
        puts e.faultCode
        puts e.faultString
        flunk(e.faultString)
      end
    end
    
  end

end
