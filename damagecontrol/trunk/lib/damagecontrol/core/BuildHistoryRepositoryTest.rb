require 'yaml'
require 'test/unit' 
require 'pebbles/mockit' 
require 'damagecontrol/core/BuildHistoryRepository'

module DamageControl

  class BuildHistoryRepositoryTest < Test::Unit::TestCase
    include FileUtils
    include MockIt

    def test_should_dump_build_to_build_dir_and_write_rss_on_register
      basedir = new_temp_dir
      build = Build.new("TestProject")

      channel = new_mock.__expect(:add_consumer)
      project_directories = new_mock
      project_directories.__expect(:build_dir) { "TestProject" }
      project_directories.__expect(:project_config_file) { File.dirname(__FILE__) + "/TestProject/conf.yaml" }
      project_directories.__expect(:build_dirs) { [] }
      project_directories.__expect(:rss_file) { "#{basedir}/rss.xml" }
      build_serializer = new_mock
      build_serializer.__expect(:dump) {|b, dir|
        assert_same(build, b)
        assert_equal("TestProject", dir)
      }
      bhr = BuildHistoryRepository.new(channel, project_directories, build_serializer)
      bhr.register(build)

      expected_rss = File.dirname(__FILE__) + "/TestProject/rss.xml"
      assert_equal(File.open(expected_rss).read, File.open("#{basedir}/rss.xml").read)
    end
    
    def test_should_lookup_build_by_dc_creation_time
      t = Time.new.utc
      b = Build.new
      
      channel = new_mock.__expect(:add_consumer)
      project_directories = new_mock.__expect(:build_dir) do |project_name, dc_creation_time| 
        assert_equal("jalla", project_name)
        assert_equal(t, dc_creation_time)
        "some_dir"
      end
      build_serializer = new_mock
      build_serializer.__expect(:load) do |dir, with_changesets|
        assert_equal("some_dir", dir)
        assert(!with_changesets)
        b
      end
      bhr = BuildHistoryRepository.new(channel, project_directories, build_serializer)

      assert_equal(b, bhr.lookup("jalla", t))
    end

    def Xtest_ignores_queued_builds_when_requesting_current_build
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock)

      build1 = Build.new("project_name")
      build1.dc_creation_time = Time.utc(2004, 04, 02, 12, 00, 00)
      build1.status = Build::BUILDING
      bhr.register(build1)
      assert_equal(build1, bhr.current_build("project_name"))
      
      build2 = Build.new("project_name")
      build2.dc_creation_time = Time.utc(2004, 04, 02, 13, 00, 00)
      build2.status = Build::QUEUED
      bhr.register(build2)
      assert_equal(build1, bhr.current_build("project_name"))
    end
  
    def Xtest_can_get_last_completed_build_of_a_project
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock)

      assert_equal(nil, bhr.last_completed_build("project_name"))
      
      build1 = Build.new("project_name")
      build1.dc_creation_time = Time.utc(2004, 04, 02, 12, 00, 00)
      build1.status = Build::BUILDING
      bhr.register(build1)
      assert_equal(nil, bhr.last_completed_build("project_name"))
      
      build2 = Build.new("project_name")
      build2.dc_creation_time = Time.utc(2004, 04, 02, 13, 00, 00)
      build2.status = Build::SUCCESSFUL
      bhr.register(build2)
      assert_equal(build2, bhr.last_completed_build("project_name"))
      
      build3 = Build.new("project_name")
      build3.dc_creation_time = Time.utc(2004, 04, 02, 14, 00, 00)
      build3.status = Build::FAILED
      bhr.register(build3)
      assert_equal(build3, bhr.last_completed_build("project_name"))
    end
    
    def Xtest_can_get_last_successful_build_of_a_project
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock)

      assert_equal(nil, bhr.last_successful_build("project_name"))

      build1 = Build.new("project_name")
      build1.dc_creation_time = Time.utc(2004, 04, 02, 12, 00, 00)
      build1.status = Build::SUCCESSFUL

      build2 = Build.new("project_name") 
      build2.dc_creation_time = Time.utc(2004, 04, 02, 13, 00, 00) # one hour later
      build2.status = Build::SUCCESSFUL

      failed_build = Build.new("project_name")
      failed_build.dc_creation_time = Time.utc(2004, 04, 02, 14, 00, 00) # two hours later
      failed_build.status = Build::FAILED
      bhr.register(build1)
      bhr.register(build2)
      bhr.register(failed_build)
      
      assert_equal(build2, bhr.last_successful_build("project_name"))
    end
    
    def Xtest_same_build_registered_twice_doesnt_add_twice
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock)

      build1 = Build.new("project_name")
      build1.dc_creation_time = Time.utc(2004, 04, 02, 12, 00, 00)

      build2 = Build.new("project_name") 
      build2.dc_creation_time = Time.utc(2004, 04, 02, 13, 00, 00) # one hour later

      bhr.register(build1)
      bhr.register(build1)
      bhr.register(build2)
      bhr.register(build1)

      assert_equal([build1, build2], bhr.history("project_name"))
    end

    def Xtest_project_names_are_alphabetically_sorted
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock)

      build1 = Build.new("foo")
      build1.dc_creation_time = Time.utc(2004, 04, 02, 12, 00, 00)

      build2 = Build.new("zap") 
      build2.dc_creation_time = Time.utc(2004, 04, 02, 13, 00, 00) # one hour later

      build3 = Build.new("bar")
      build3.dc_creation_time = Time.utc(2004, 04, 02, 12, 00, 00)

      bhr.register(build1)
      bhr.register(build2)
      bhr.register(build3)

      assert_equal(["bar", "foo", "zap"], bhr.project_names)
    end
    
    def REACTIVATE_WHEN_INDEX_BASED_SEARCH_IMPLEMENTED_test_should_allow_searching_in_anything
      time = Time.new.utc
      a = Build.new("test", time)
      b = Build.new("test", time + 1)
      c = Build.new("test", time + 2)
      
      b.changesets.add(Change.new("some/where", "aslak", "funny message", "r1", time))
      b.changesets.add(Change.new("some/where/else", "aslak", "funny message again", "r1", time))
      c.changesets.add(Change.new("some/path", "jon", "some other funny message", "r1", time))
     
      @bhr.register(a)
      @bhr.register(b)
      @bhr.register(c)

      assert_equal([b,c], @bhr.search(/funny/))
      assert_equal([c], @bhr.search(/some\/path/))
      assert_equal([a,b,c], @bhr.search(/test/))
    end

    def REACTIVATE_WHEN_INDEX_BASED_SEARCH_IMPLEMENTED_test_should_only_search_in_project_when_project_name_specified
      time = Time.new.utc
      a = Build.new("test", time)
      b = Build.new("test", time + 1)
      c = Build.new("onlythisone", time + 2)
      
      b.changesets.add(Change.new("some/where", "aslak", "funny message", "r1", time))
      b.changesets.add(Change.new("some/where/else", "aslak", "funny message again", "r1", time))
      c.changesets.add(Change.new("some/path", "jon", "some other funny message", "r1", time))
      
      @bhr.register(a)
      @bhr.register(b)
      @bhr.register(c)

      assert_equal([c], @bhr.search(/funny/, "onlythisone"))
    end
    
    def Xtest_should_find_previous_and_next
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock)

      a = Build.new("test")
      a.dc_creation_time = Time.utc(2004)
      b = Build.new("test")
      b.dc_creation_time = a.dc_creation_time + 10
      bhr.register(a)
      bhr.register(b)

      assert_equal(b, bhr.next(a))
      assert_equal(nil, bhr.next(b))
      assert_equal(a, bhr.prev(b))
      assert_equal(nil, bhr.prev(a))
    end

    def Xtest_to_rss
      bhr = BuildHistoryRepository.new(new_mock.__expect(:add_consumer), new_mock, "http://builds.codehause.org/somewhere/")

      b1 = Build.new("myproject")
      b1.dc_creation_time = Time.utc(2005)
      b1.label = "happy new year"
      b1.status = Build::SUCCESSFUL

      b2 = Build.new("myproject")
      b2.dc_creation_time = b1.dc_creation_time + 1000
      b2.status = Build::FAILED
      bhr.register(b1)
      bhr.register(b2)

      expected_rss = File.open("#{damagecontrol_home}/testdata/rss.xml").read.chomp
      rss = bhr.to_rss("myproject").chomp
      assert_equal(expected_rss, rss)
    end
  end
end
