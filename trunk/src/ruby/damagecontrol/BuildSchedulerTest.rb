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
      @scheduler.add_executor(@executor)
      @build = Build.new("project")
    end
    
    def test_fail
      fail "selftest"
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
      
      @executor.build_done
      
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
      @executor.build_done
      @scheduler.force_tick
      assert_equal(project1_build, @executor.scheduled_build)
      @executor.build_done
      @scheduler.force_tick
      assert_equal(project2_build, @executor.scheduled_build)
      
    end
    
  end
end