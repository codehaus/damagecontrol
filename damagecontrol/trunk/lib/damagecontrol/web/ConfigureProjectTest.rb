require 'test/unit'
require 'net/http'
require 'pebbles/mockit'
require 'damagecontrol/DamageControlServer'
require 'rubygems'
require_gem 'rscm'

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
      sleep 5
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
      response, data = store_configuration("Chicago")
      assert_response_ok(response)
      assert(@server.project_config_repository.project_exists?("Chicago"))
      assert_equal("Chicago",@server.project_config_repository.project_config("Chicago")["project_name"])
    end
    
    def test_asks_for_project_name_when_project_name_not_specified
      response, data = @client.get("/private/configure")
      assert_response_ok(response)
      assert_match(/Project name/, data)
    end

    def test_fills_in_project_name_if_specified_in_url
      response, data = store_configuration("Milano")
      response, data = @client.get("/private/configure/Milano")
      assert_response_ok(response)
      assert_match(/Milano/, data)
    end
    
    def assert_response_ok(response)
      # redirect or ok
      assert("302" == response.code || "200" == response.code)
    end

  private
    def store_configuration(project_name)
      @client.post("/private/configure/#{project_name}", "action=store_configuration&scm_id=#{RSCM::CVS.name}")
    end

  end

end
