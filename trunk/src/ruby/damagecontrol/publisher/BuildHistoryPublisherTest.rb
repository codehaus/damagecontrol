$:<<'../../lib'

require 'yaml'
require 'test/unit' 
require 'mockit' 
require 'damagecontrol/Hub'
require 'damagecontrol/publisher/BuildHistoryPublisher'
require 'damagecontrol/publisher/AbstractBuildHistoryTest'

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
    
    def test_number_of_builds_per_project_can_be_specified
      apple_list = @bhp.get_build_list_map(nil, 1)["apple"]
      assert_equal([@apple2], apple_list)
      pear_list = @bhp.get_build_list_map(nil, 1)["pear"]
      assert_equal([@pear1], pear_list)
    end

    def test_prohect_names_are_correct
      project_names = @bhp.get_project_names
      assert_equal(["apple", "pear"], project_names)
    end
    
    def test_register_build_saves_as_yaml
      bhp = BuildHistoryPublisher.new(Hub.new, "test.yaml")

      bhp.register(@apple1)
      bhp.register(@pear1)
      bhp.register(@apple2)

      expected = YAML::dump(bhp.get_build_list_map())
      
      written = File.new("test.yaml")
      written_content = written.read
      written.close
      assert_equal(expected, written_content)
    end
    
    def teardown
#      File.delete("test.yaml") if File.exist?("test.yaml")
    end
    
    PERSISTED_YAML_DATA = <<-EOF
--- 
apple: 
  - !ruby/object:DamageControl::Build 
    config: 
      build_command_line: Apple1
    modification_set: []
    project_name: apple
    successful: true
    timestamp: "20040316225946"
  - !ruby/object:DamageControl::Build 
    config: 
      build_command_line: Apple2
    modification_set: []
    project_name: apple
    successful: false
    timestamp: "20040316225948"
pear: 
  - !ruby/object:DamageControl::Build 
    config: 
      build_command_line: Pear1
    modification_set: []
    project_name: pear
    timestamp: "20040316225947"
    EOF

    def test_persisted_build_history_should_be_loaded
      expected_builds = YAML::load(PERSISTED_YAML_DATA)
      
      testfile = File.open("test.yaml", "w")
      testfile.print(PERSISTED_YAML_DATA)
      testfile.close
      bhp = BuildHistoryPublisher.new(Hub.new,"test.yaml")
      assert_equal(expected_builds, bhp.get_build_list_map)
    end
    
    def test_build_request_messages_will_register_build
      @bhp.process_message(BuildRequestEvent.new(Build.new("1")))
      assert_equal("1", @bhp.get_build_list_map("1")["1"][0].project_name)

      @bhp.process_message(BuildStartedEvent.new(Build.new("2")))
      assert_equal("2", @bhp.get_build_list_map("2")["2"][0].project_name)

      @bhp.process_message(BuildCompleteEvent.new(Build.new("3")))
      assert_equal("3", @bhp.get_build_list_map("3")["3"][0].project_name)

      @bhp.process_message(BuildProgressEvent.new(Build.new("4"), nil))
      assert_nil(@bhp.get_build_list_map("4"))
    end

    def TODO_test_register_build_saves_as_yaml_and_filters_out_old_builds_so_the_file_doesnt_grow_too_big
    end
    
  end
end
