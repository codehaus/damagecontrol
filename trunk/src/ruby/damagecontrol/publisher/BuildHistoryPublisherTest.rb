$:<<'../../lib'

require 'yaml'
require 'test/unit' 
require 'mockit' 
require 'xmlrpc/server'
require "xmlrpc/client"
require "xmlrpc/config"
require "xmlrpc/utils"
require 'webrick'
require 'damagecontrol/publisher/BuildHistoryPublisher'
require 'damagecontrol/publisher/AbstractBuildHistoryTest'
require 'cgi'

module DamageControl

  class BuildHistoryPublisherTest < AbstractBuildHistoryTest
    
    # Not really a unit test, more a YAML experiment
    def test_build_can_be_saved_as_yaml
      builds = [@apple1, @pear1, @apple1]
      yaml = ""
      YAML::dump(builds, yaml)
      builds2 = YAML::load(yaml)
      assert_equal(@pear1.config["build_command_line"], builds2[1].config["build_command_line"])
    end
    
    def test_builds_with_same_name_are_grouped_in_map_with_one_key
      apple_list = @bhp.get_build_list_map("apple")["apple"]
      assert_equal([@apple1, @apple2], apple_list)
    end
    
    def test_same_build_registered_twice_doesnt_add_twice
      @bhp.register(@apple2)
      apple_list = @bhp.get_build_list_map("apple")["apple"]
      assert_equal([@apple1, @apple2], apple_list)      
    end

    def test_all_builds_are_returned_when_no_project_name_is_specified
      apple_list = @bhp.get_build_list_map()["apple"]
      assert_equal([@apple1, @apple2], apple_list)
      pear_list = @bhp.get_build_list_map()["pear"]
      assert_equal([@pear1], pear_list)
    end
    
    def test_prohect_names_are_correct
      project_names = @bhp.get_project_names
      assert_equal(["apple", "pear"], project_names)
    end
    
    def TODO_test_register_build_saves_as_yaml
      file = ""
      bhp = BuildHistoryPublisher.new(file)
      bhp.register(@apple1)
      bhp.register(@pear1)
      bhp.register(@apple2)
      
      assert_equal(YAML::dump(bhp.get_build_list_map()), file)
    end
    
    def TODO_test_register_build_saves_as_yaml_and_filters_out_old_builds
    end
    
    def TODO_test_number_of_builds_per_project_can_be_specified
    end
    
    def TODO_test_all_build_messages_will_register_build
    end
  end
end
