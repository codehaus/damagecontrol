$:<<'../../lib'

require 'yaml'
require 'test/unit' 
require 'mockit' 
require 'damagecontrol/Hub'
require 'damagecontrol/BuildHistoryRepository'
require 'damagecontrol/AbstractBuildHistoryTest'

module DamageControl

  class BuildHistoryRepositoryTest < AbstractBuildHistoryTest
  
  	def test_can_get_last_succesful_build_of_a_project
  	  assert_equal(nil, @bhp.last_succesful_build("project_name"))

  	  build1 = Build.new("project_name")
  	  build1.timestamp = Time.utc(2004, 04, 02, 12, 00, 00)
  	  build1.status = Build::SUCCESSFUL
  	  build2 = Build.new("project_name")
  	  build2.timestamp = Time.utc(2004, 04, 02, 13, 00, 00) # one hour later
  	  build2.status = Build::SUCCESSFUL
  	  failed_build = Build.new("project_name")
  	  failed_build.timestamp = Time.utc(2004, 04, 02, 14, 00, 00) # one hour later
  	  failed_build.status = Build::FAILED
  	  @bhp.register(build2)
  	  @bhp.register(build1)
  	  @bhp.register(failed_build)
  	  assert_equal([build1, build2, failed_build], @bhp.build_history("project_name"))
  	  
  	  assert_equal(build2, @bhp.last_succesful_build("project_name"))
  	end
    
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
    
    def test_get_build_list_map_with_empty_history_returns_empty_map
      bhp = BuildHistoryRepository.new(Hub.new)
      should_be_empty = bhp.get_build_list_map()
      should_also_be_empty = bhp.get_build_list_map("foo")
      assert_equal(Hash.new, should_be_empty)
      assert_equal(Hash.new, should_also_be_empty)
    end
    
    def test_register_build_saves_as_yaml
      bhp = BuildHistoryRepository.new(Hub.new, "test.yaml")

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
      File.delete("test.yaml") if File.exist?("test.yaml")
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
      bhp = BuildHistoryRepository.new(Hub.new,"test.yaml")
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
      assert_equal(Hash.new, @bhp.get_build_list_map("4"))
    end

    def TODO_test_register_build_saves_as_yaml_and_filters_out_old_builds_so_the_file_doesnt_grow_too_big
    end
    
  end
end
