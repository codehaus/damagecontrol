require 'test/unit'
require 'net/http'
require 'pebbles/mockit'
require 'damagecontrol/DamageControlServer'

module DamageControl

  class ConfigureProjectTest < Test::Unit::TestCase
    include FileUtils
  
    def setup
      @server = DamageControlServer.new(
        :RootDir => new_temp_dir,
        :SocketTriggerPort => 14711,
        :HttpPort => 14712
      )
      @server.start
      @client = Net::HTTP.new("localhost", 14712)
    end

    def teardown
      @server.shutdown
    end

    def test_provides_content_at_base_url
      response, data = @client.get("/private/project")
      assert_response_ok(response)
    end

    def test_creates_new_project_when_complete_project_data_is_posted
      response, data = @client.post("/private/project", "action=store_configuration&project_name=Chicago")
      assert_response_ok(response)
      assert(@server.project_config_repository.project_exists?("Chicago"))
    end
    
    def test_asks_for_project_name
      response, data = @client.get("/private/project?action=configure")
      assert_response_ok(response)
      assert_match(/Project name/, data)
    end

    def test_fills_in_project_name_if_specified_in_url
      response, data = @client.get("/private/project?project_name=Milano")
      assert_response_ok(response)
      assert_match(/Milano/, data)
    end
    
    def assert_response_ok(response)
      # redirect or ok
      assert("302" == response.code || "200" == response.code)
    end

end

end
