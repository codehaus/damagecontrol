require 'damagecontrol/core/FixedTimeScheduler'

require 'test/unit'
require 'pebbles/mockit'

module DamageControl

  class FixedTimeSchedulerTest < Test::Unit::TestCase
  
    include MockIt
    
    def setup
      @scheduled_build_time = Time.utc(1977, 9, 20, 8, 5, 0)
    end
    
    def test_should_request_build_if_tick_at_exact_time
      hub = new_mock
      hub.__expect(:put) do |message| 
        assert(message.is_a?(BuildRequestEvent))
        assert_equal(@scheduled_build_time, message.build.dc_creation_time)
      end

      time_scheduler = FixedTimeScheduler.new(
        hub,
        1,
        project_config_repository_with_one_project(project_config_with_scheduled_build_time, @scheduled_build_time), 
        non_busy_build_scheduler)                 
      time_scheduler.tick(@scheduled_build_time)
    end
    
    def test_should_not_build_unscheduled_project
      time_scheduler = FixedTimeScheduler.new(
        new_mock,
        1,
        project_config_repository_with_one_project(project_config_without_scheduled_build_time, nil), 
        new_mock)        
      time_scheduler.tick(100)
    end
    
    def test_should_not_request_build_if_build_scheduled
      build_scheduler = new_mock
      build_scheduler.__expect(:project_scheduled?) {|project_name|
        assert_equal("project", project_name)
        true
      }

      time_scheduler = FixedTimeScheduler.new(
        new_mock,
        1,
        project_config_repository_with_one_project(project_config_with_scheduled_build_time, @scheduled_build_time), 
        build_scheduler)                  
      time_scheduler.tick(@scheduled_build_time)      
    end

    def test_should_not_request_build_if_project_building
      build_scheduler = new_mock
      build_scheduler.__expect(:project_scheduled?) {|project_name|
        assert_equal("project", project_name)
        false
      }
      build_scheduler.__expect(:project_building?) {|project_name|
        assert_equal("project", project_name)
        true
      }

      time_scheduler = FixedTimeScheduler.new(
        new_mock,
        1,
        project_config_repository_with_one_project(project_config_with_scheduled_build_time, @scheduled_build_time), 
        build_scheduler)                  
      time_scheduler.tick(@scheduled_build_time)      
    end
    
    def test_should_request_build_if_within_interval
      about_one_hour_before = @scheduled_build_time - (60 * 55)
      five_minutes_after    = @scheduled_build_time + (60 * 5)
      about_one_hour_after  = @scheduled_build_time + (60 * 65)
      about_one_day_after   = five_minutes_after + (60 * 60 *24)

      hub = new_mock
      project_config_repository = project_config_repository_with_one_project(project_config_with_scheduled_build_time, five_minutes_after)
      time_scheduler = FixedTimeScheduler.new(
        hub,
        3600, # tick ever hour
        project_config_repository, 
        non_busy_build_scheduler)

      time_scheduler.tick(about_one_hour_before)
      hub.__verify

      hub.__expect(:put) do |message| 
        assert(message.is_a?(BuildRequestEvent))
        assert_equal(five_minutes_after, message.build.dc_creation_time)
      end
      time_scheduler.tick(five_minutes_after)
      hub.__verify

      time_scheduler.tick(about_one_hour_after)
      hub.__verify

      hub.__expect(:put) do |message| 
        assert(message.is_a?(BuildRequestEvent))
        assert_equal(about_one_day_after, message.build.dc_creation_time)
      end
      project_config_repository.__expect(:create_build) do |project_name |
        assert_equal("project", project_name)
        build = Build.new("project")
        build.dc_creation_time = about_one_day_after
        build
      end
      time_scheduler.tick(about_one_day_after)
      hub.__verify      
    end

    def project_config_with_scheduled_build_time
      { "fixed_build_time_hhmm" => "08:05" }
    end
    
    def project_config_without_scheduled_build_time
      {}
    end
    
    def non_busy_build_scheduler
      build_scheduler = new_mock
      build_scheduler.__setup(:project_scheduled?) {|project_name|
        assert_equal("project", project_name)
        false
      }
      build_scheduler.__setup(:project_building?) {|project_name|
        assert_equal("project", project_name)
        false
      }
      build_scheduler
    end
    
    def project_config_repository_with_one_project(config, build_creation_time)
      project_config_repository = new_mock
      project_config_repository.__setup(:project_names) { ["project"] }
      project_config_repository.__setup(:project_config) {|project_name|
        assert_equal("project", project_name)
        config
      }
      project_config_repository.__setup(:create_build) {|project_name |
        assert_equal("project", project_name)
        build = Build.new("project")
        build.dc_creation_time = build_creation_time
        build
      }
      project_config_repository
    end

  end

end