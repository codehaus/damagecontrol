require 'test/unit'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/BuildScheduler'

module DamageControl

  class BuildSchedulerTest < Test::Unit::TestCase
  
    include HubTestHelper
    
    def setup
      create_hub
      @executor = BuildExecutor.new(hub)
      @scheduler = BuildScheduler.new(hub)
      @scheduler.default_quiet_period = 0
      @scheduler.add_executor(@executor)
      @build = Build.new("project")
    end
    
    def test_build_is_scheduled_on_available_executor
    
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      
      assert_equal(@build, @executor.scheduled_build)
    
    end
    
    def test_build_is_not_scheduled_on_busy_executor
    
      other_build = Build.new
      @executor.schedule_build(other_build)
      
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      
      assert_equal(other_build, @executor.scheduled_build)
      
    end
    
    def test_build_is_sheduled_on_first_available_executor_only
    
      hub.publish_message(BuildRequestEvent.new(@build))
      other_executor = BuildExecutor.new(hub)
      @scheduler.add_executor(other_executor)
      @scheduler.force_tick
      
      assert_equal(@build, @executor.scheduled_build)
      assert(!other_executor.busy?)
      
      
    end
    
    def test_queued_build_is_scheduled_when_executor_is_available
    
      hub.publish_message(BuildRequestEvent.new(@build))
      other_build = Build.new
      hub.publish_message(BuildRequestEvent.new(other_build))
      @scheduler.force_tick
      
      assert_equal(@build, @executor.scheduled_build)
      
      @executor.build_complete
      
      assert_equal(nil, @executor.scheduled_build)
      assert_not_nil(@scheduler.find_available_executor)
      @scheduler.force_tick
      assert_equal(other_build, @executor.scheduled_build)
      
    end
    
    def test_three_requests_from_three_different_projects_are_queued_and_then_scheduled
    
      project1_build = Build.new("project1")
      project2_build = Build.new("project2")
      
      hub.publish_message(BuildRequestEvent.new(@build))
      hub.publish_message(BuildRequestEvent.new(project1_build))
      hub.publish_message(BuildRequestEvent.new(project2_build))
      @scheduler.force_tick
      
      assert_equal(@build, @executor.scheduled_build)
      @executor.build_complete
      @scheduler.force_tick
      assert_equal(project1_build, @executor.scheduled_build)
      @executor.build_complete
      @scheduler.force_tick
      assert_equal(project2_build, @executor.scheduled_build)
      
    end
    
    def test_request_from_same_project_twice_removes_earlier_entries_in_queue
    
      @build.timestamp = 1
      build2 = Build.new("project")
      build2.timestamp = 2
      build3 = Build.new("project")
      build3.timestamp = 3

      @scheduler.schedule_build(@build)
      # first build will get scheduled on executor
      assert_equal([ ], @scheduler.build_queue)
      
      @scheduler.schedule_build(build2)
      assert_equal([ build2 ], @scheduler.build_queue)
      
      @scheduler.schedule_build(build3)
      assert_equal([ build3 ], @scheduler.build_queue)

      @scheduler.schedule_build(build2)
      assert_equal([ build3 ], @scheduler.build_queue)
      
      assert_equal([ build3 ], @scheduler.build_queue)
      
    end
    
    def test_quiet_period_elapsed_works_uses_specified_quiet_period
      @scheduler.clock = FakeClock.new
      @scheduler.clock.change_time(0)
      
      @build.timestamp = 0
      assert(@scheduler.quiet_period_elapsed?(@build))
      @build.config["quiet_period"] = 100
      assert_equal(100, @scheduler.quiet_period(@build))
      assert_equal(0, @scheduler.current_time)
      assert_equal(0, @build.timestamp_as_i)
      assert(!@scheduler.quiet_period_elapsed?(@build))
      @scheduler.clock.change_time(100)
      assert(@scheduler.quiet_period_elapsed?(@build))
    end
    
    def test_build_scheduled_after_quiet_period_has_elapsed
      
      @build.timestamp = 0
      @build.config["quiet_period"] = 100
      
      assert(!@executor.busy?)

      @scheduler.clock = FakeClock.new
      @scheduler.clock.change_time(0)
      
      @scheduler.schedule_build( @build )
      
      assert(!@executor.busy?)
      
      @scheduler.force_tick(101)
      assert(@scheduler.quiet_period_elapsed?(@build))
      assert(@executor.busy?)
      
    end
    
  end
end 
