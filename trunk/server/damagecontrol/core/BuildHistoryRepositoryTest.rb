require 'yaml'
require 'test/unit' 
require 'pebbles/mockit' 
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/AbstractBuildHistoryTest'
require 'damagecontrol/scm/Changes'

module DamageControl

  class BuildHistoryRepositoryTest < AbstractBuildHistoryTest
    include MockIt
  
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
    
    def test_ignores_queued_builds_when_requesting_current_build
      assert_equal(nil, @bhp.current_build("project_name"))
      
      build1 = Build.new("project_name")
      build1.timestamp = Time.utc(2004, 04, 02, 12, 00, 00)
      build1.status = Build::BUILDING
      @bhp.register(build1)
      assert_equal(build1, @bhp.current_build("project_name"))
      
      build2 = Build.new("project_name")
      build2.timestamp = Time.utc(2004, 04, 02, 13, 00, 00)
      build2.status = Build::QUEUED
      @bhp.register(build2)
      assert_equal(build1, @bhp.current_build("project_name"))
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
    
    def test_can_get_last_successful_build_of_a_project
      assert_equal(nil, @bhp.last_successful_build("project_name"))

      build1 = Build.new("project_name", Time.utc(2004, 04, 02, 12, 00, 00))
      build1.status = Build::SUCCESSFUL
      build2 = Build.new("project_name", Time.utc(2004, 04, 02, 13, 00, 00)) # one hour later
      build2.status = Build::SUCCESSFUL
      failed_build = Build.new("project_name", Time.utc(2004, 04, 02, 14, 00, 00)) # two hours later
      failed_build.status = Build::FAILED
      @bhp.register(build1)
      @bhp.register(build2)
      @bhp.register(failed_build)
      assert_equal([build1, build2, failed_build], @bhp.history("project_name"))
      
      assert_equal(build2, @bhp.last_successful_build("project_name"))
    end
    
    def test_build_history_is_organised_by_name
      build1 = Build.new("project_name", Time.utc(2004, 04, 02, 12, 00, 00))
      build2 = Build.new("project_name", Time.utc(2004, 04, 02, 13, 00, 00)) # one hour later
      build3 = Build.new("project_name", Time.utc(2004, 04, 02, 14, 00, 00)) # two hours later

      @bhp.register(build1)
      @bhp.register(build2)
      @bhp.register(build3)
      
      assert_equal([build1, build2, build3], @bhp.history("project_name"))
    end
    
    # Not really a unit test, more a YAML experiment
    def test_build_can_be_saved_as_yaml
      builds = [@apple1, @pear1, @apple1]
      yaml = ""
      YAML::dump(builds, yaml)
      builds2 = YAML::load(yaml)
      assert_equal(@pear1.config["build_command_line"], builds2[1].config["build_command_line"])
    end
    
    def test_same_build_registered_twice_doesnt_add_twice
      @bhp.register(@apple2)
      @bhp.register(@apple2)
      @bhp.register(@apple2)
      apple_list = @bhp.history("apple")
      assert_equal([@apple1, @apple2], apple_list)      
    end

    def test_project_names_are_correct
      project_names = @bhp.project_names
      assert_equal(["apple", "pear"], project_names)
    end
    
    def test_init_with_pd_reads_yaml
      mock_project_directories = new_mock
      mock_project_directories.__expect(:project_names) {
        ["tea", "coffee"]
      }
      mock_project_directories.__expect(:build_history_file) { |project_name|
        assert_equal("tea", project_name)
        "tea.yaml"
      }
      mock_project_directories.__expect(:build_history_file) { |project_name|
        assert_equal("coffee", project_name)
        "coffee.yaml"
      }
      bhp = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), mock_project_directories)
    end
    
    def test_register_with_pd_writes_yaml
      mock_project_directories = new_mock
      mock_project_directories.__expect(:project_names) {
        []
      }
      tempdir = new_temp_dir("build_history_repository_test")
      File.mkpath(tempdir)

      mock_project_directories.__expect(:build_history_file) { |project_name|
        assert_equal("pear", project_name)
        "#{tempdir}/pear.yaml"
      }
      mock_project_directories.__expect(:build_history_file) { |project_name|
        assert_equal("apple", project_name)
        "#{tempdir}/apple.yaml"
      }
      bhp = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), mock_project_directories)
      bhp.register(@pear1) # should not save, build not complete
      bhp.register(@apple1)

      assert(File.exists?("#{tempdir}/pear.yaml"))
      assert(File.exists?("#{tempdir}/apple.yaml"))

    end
    
    def teardown
      File.delete("test.yaml") if File.exist?("test.yaml")
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
    
    def test_should_allow_searching_in_anything
      time = Time.new.utc
      a = Build.new("test", time)
      b = Build.new("test", time + 1)
      c = Build.new("test", time + 2)
      
      b.changesets.add(Change.new("some/where", "aslak", "funny message", "r1", time))
      b.changesets.add(Change.new("some/where/else", "aslak", "funny message again", "r1", time))
      c.changesets.add(Change.new("some/path", "jon", "some other funny message", "r1", time))
     
      @bhp.register(a)
      @bhp.register(b)
      @bhp.register(c)

      assert_equal([b,c], @bhp.search(/funny/))
      assert_equal([c], @bhp.search(/some\/path/))
      assert_equal([a,b,c], @bhp.search(/test/))
    end

    def test_should_only_search_in_project_when_project_name_specified
      time = Time.new.utc
      a = Build.new("test", time)
      b = Build.new("test", time + 1)
      c = Build.new("onlythisone", time + 2)
      
      b.changesets.add(Change.new("some/where", "aslak", "funny message", "r1", time))
      b.changesets.add(Change.new("some/where/else", "aslak", "funny message again", "r1", time))
      c.changesets.add(Change.new("some/path", "jon", "some other funny message", "r1", time))
      
      @bhp.register(a)
      @bhp.register(b)
      @bhp.register(c)

      assert_equal([c], @bhp.search(/funny/, "onlythisone"))
    end
    
    def test_should_retrieve_build_by_timestamp_string
      t = Time.utc(2004, 01, 04, 12, 00, 00)
      p1 = Build.new("t", Time.utc(2004, 01, 01, 12, 00, 00))
      pt = Build.new("t", t)
      p3 = Build.new("t", Time.utc(2004, 01, 05, 12, 00, 00))
      xt = Build.new("x", t)
      
      @bhp.register(p1)
      @bhp.register(pt)
      @bhp.register(p3)
      @bhp.register(xt)
      
      assert_equal(pt, @bhp.lookup("t", t))
      assert_equal(pt, @bhp.lookup("t", "20040104120000"))
    end

    def test_should_find_previous_and_next
      a = Build.new("test", Time.utc(2004, 01, 01, 12, 00, 00))
      b = Build.new("test", Time.utc(2004, 01, 04, 12, 00, 00))
      @bhp.register(a)
      @bhp.register(b)

      assert_equal(b, @bhp.next(a))
      assert_equal(nil, @bhp.next(b))
      assert_equal(a, @bhp.prev(b))
      assert_equal(nil, @bhp.prev(a))
    end

    def test_should_find_previous_successful_build
      b1 = Build.new("yo", Time.utc(2004, 01, 01, 12, 00, 00))
      b1.status = Build::SUCCESSFUL

      b2 = Build.new("notthis", Time.utc(2004, 01, 01, 12, 00, 01))
      b2.status = Build::SUCCESSFUL

      b3 = Build.new("yo", Time.utc(2004, 01, 01, 12, 00, 02))
      b3.status = Build::SUCCESSFUL

      b4 = Build.new("yo", Time.utc(2004, 01, 01, 12, 00, 03))
      b4.status = Build::FAILED

      b5 = Build.new("yo", Time.utc(2004, 01, 01, 12, 00, 04))

      @bhp.register(b1)
      @bhp.register(b2)
      @bhp.register(b3)
      @bhp.register(b4)
      @bhp.register(b5)

      assert_equal(b3, @bhp.previous_successful_build(b5))
      assert_equal(b3, @bhp.previous_successful_build(b4))
      assert_equal(b1, @bhp.previous_successful_build(b3))
      assert_equal(nil, @bhp.previous_successful_build(b2))
      assert_equal(nil, @bhp.previous_successful_build(b1))
    end

    def test_to_rss
      b1 = Build.new("myproject", Time.utc(2004, 9, 3, 15, 0, 0))
      b1.status = Build::SUCCESSFUL
      b2 = Build.new("myproject", Time.utc(2004, 9, 4, 15, 0, 0))
      b2.status = Build::FAILED
      @bhp.register(b1)
      @bhp.register(b2)

      rss = @bhp.to_rss("myproject", "http://builds.codehause.org/somewhere")
      assert_equal("2.0", rss.root.attributes["version"])
      assert_equal("DamageControl: myproject", rss.get_text("rss/channel/title").value)
      assert_equal("http://builds.codehause.org/somewhere", rss.get_text("rss/channel/link").value)
      assert_equal(2, rss.root.get_elements("channel/item").length)
    end
  end
end
