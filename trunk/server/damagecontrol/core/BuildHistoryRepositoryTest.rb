require 'yaml'
require 'test/unit' 
require 'pebbles/mockit' 
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/AbstractBuildHistoryTest'

module DamageControl

  class BuildHistoryRepositoryTest < AbstractBuildHistoryTest
  
    def test_can_get_current_build
      assert_equal(nil, @bhp.current_build("project_name"))
      
      build1 = Build.new("project_name")
      build1.timestamp = Time.utc(2004, 04, 02, 12, 00, 00)
      build1.status = Build::BUILDING
      @bhp.register(build1)
      assert_equal(build1, @bhp.current_build("project_name"))
      
      build2 = Build.new("project_name")
      build2.timestamp = Time.utc(2004, 04, 02, 13, 00, 00)
      build2.status = Build::BUILDING
      @bhp.register(build2)
      assert_equal(build2, @bhp.current_build("project_name"))
    end
  
    def test_can_get_last_completed_build_of_a_project
      assert_equal(nil, @bhp.last_completed_build("project_name"))
      
      build1 = Build.new("project_name")
      build1.timestamp = Time.utc(2004, 04, 02, 12, 00, 00)
      build1.status = Build::BUILDING
      @bhp.register(build1)
      assert_equal(nil, @bhp.last_completed_build("project_name"))
      
      build2 = Build.new("project_name")
      build2.timestamp = Time.utc(2004, 04, 02, 13, 00, 00)
      build2.status = Build::SUCCESSFUL
      @bhp.register(build2)
      assert_equal(build2, @bhp.last_completed_build("project_name"))
      
      build3 = Build.new("project_name")
      build3.timestamp = Time.utc(2004, 04, 02, 14, 00, 00)
      build3.status = Build::FAILED
      @bhp.register(build3)
      assert_equal(build3, @bhp.last_completed_build("project_name"))
    end
    
    def test_can_get_last_succesful_build_of_a_project
      assert_equal(nil, @bhp.last_succesful_build("project_name"))

      build1 = Build.new("project_name", Time.utc(2004, 04, 02, 12, 00, 00))
      build1.status = Build::SUCCESSFUL
      build2 = Build.new("project_name", Time.utc(2004, 04, 02, 13, 00, 00)) # one hour later
      build2.status = Build::SUCCESSFUL
      failed_build = Build.new("project_name", Time.utc(2004, 04, 02, 14, 00, 00)) # two hours later
      failed_build.status = Build::FAILED
      @bhp.register(build2)
      @bhp.register(build1)
      @bhp.register(failed_build)
      assert_equal([build1, build2, failed_build], @bhp.build_history("project_name"))
      
      assert_equal(build2, @bhp.last_succesful_build("project_name"))
    end
    
    def test_build_history_is_sorted_according_to_timestamp
  	  build1 = Build.new("project_name", Time.utc(2004, 04, 02, 12, 00, 00))
  	  build2 = Build.new("project_name", Time.utc(2004, 04, 02, 13, 00, 00)) # one hour later
  	  build3 = Build.new("project_name", Time.utc(2004, 04, 02, 14, 00, 00)) # two hours later

      @bhp.register(build3)
      @bhp.register(build1)
      @bhp.register(build2)
      
  	  assert_equal([build1, build2, build3], @bhp.build_history("project_name"))
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
      assert_equal({}, @bhp.get_build_list_map("4"))
    end

    def test_should_be_able_to_group_builds_per_week_month_and_day
      week_zero_one = Build.new("test", Time.utc(2004, 01, 01, 12, 00, 00))

      week_zero_two = Build.new("test", Time.utc(2004, 01, 04, 12, 00, 00))

      week_one_one = Build.new("test", Time.utc(2004, 01, 05, 12, 00, 00))

      week_one_two = Build.new("test", Time.utc(2004, 01, 11, 12, 00, 00))

      week_two_one = Build.new("test", Time.utc(2004, 01, 12, 12, 00, 00))
      
      week_eight_one = Build.new("test", Time.utc(2004, 02, 28, 12, 00, 00))
      
      week_eight_two = Build.new("test", Time.utc(2004, 02, 28, 13, 00, 00))
      
      @bhp.register(week_zero_one)
      @bhp.register(week_zero_two)
      @bhp.register(week_one_one)
      @bhp.register(week_one_two)
      @bhp.register(week_two_one)
      @bhp.register(week_eight_one)
      @bhp.register(week_eight_two)
      
      week_builds = @bhp.group_by_period("test", :week)

      builds_per_week_zero = week_builds[Time.utc(2003, 12, 29)]
      assert_equal([week_zero_one, week_zero_two], builds_per_week_zero)
      builds_per_week_one = week_builds[Time.utc(2004, 01, 05)]
      assert_equal([week_one_one, week_one_two], builds_per_week_one)
      builds_per_week_two = week_builds[Time.utc(2004, 01, 12)]
      assert_equal([week_two_one], builds_per_week_two)
      builds_per_week_two = week_builds[Time.utc(2004, 01, 12)]
      assert_equal([week_two_one], builds_per_week_two)
      builds_per_week_eight = week_builds[Time.utc(2004, 02, 23)]
      assert_equal([week_eight_one, week_eight_two], builds_per_week_eight)

      day_builds = @bhp.group_by_period("test", :day)
      builds_per_aslaks_birthday = day_builds[Time.utc(2004, 02, 28)]
      assert_equal([week_eight_one, week_eight_two], builds_per_aslaks_birthday)

      month_builds = @bhp.group_by_period("test", :month)
      builds_per_january = month_builds[Time.utc(2004, 01, 01)]
      assert_equal([week_zero_one, week_zero_two, week_one_one, week_one_two, week_two_one], builds_per_january)
    end

  end
end
