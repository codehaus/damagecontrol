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
    end

    def teardown
      @server.shutdown
    end

    def test_provides_content_at_base_url
      client = Net::HTTP.new("localhost", 4712)
      response, data = client.get("/private/admin")
      assert_equal("200", response.code)
    end

    def test_creates_new_project_when_complete_project_data_is_posted
      client = Net::HTTP.new("localhost", 4712)
      response, data = client.post("/private/admin", "command=store_configuration&project_name=Chicago")
      assert_equal("200", response.code)
      assert(@server.project_config_repository.project_exists?("Chicago"))
    end
    
    def test_asks_for_project_name
      client = Net::HTTP.new("localhost", 4712)
      response, data = client.get("/private/admin")
      assert_equal("200", response.code)
      assert_match(/Project Name/, data)
    end

    def test_fills_in_project_name_if_specified_in_url
      client = Net::HTTP.new("localhost", 4712)
      response, data = client.get("/private/admin?project_name=Milano")
      assert_equal("200", response.code)
      assert_match(/Project Name/, data)
      assert_match(/Milano/, data)
    end

end

end
