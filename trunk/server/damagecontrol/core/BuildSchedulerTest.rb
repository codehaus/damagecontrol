require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/BuildScheduler'

module DamageControl

  class BuildSchedulerTest < Test::Unit::TestCase
  
    include FileUtils
    
    def setup
      @mock_hub = MockIt::Mock.new
      @mock_hub.__expect(:add_consumer) {|consumer| assert(consumer.is_a?(BuildScheduler))}
      @scheduler = BuildScheduler.new(@mock_hub, 0)

      @mock_executor = MockIt::Mock.new
      @scheduler.add_executor(@mock_executor)

      @build = Build.new("project")
    end
    
    def test_build_is_scheduled_on_available_executor
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| assert_same(@build, b) ; true }
      @mock_executor.__expect(:put) {|b| assert_same(@build, b) }
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_build_is_not_executed_on_busy_executor
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| false }
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
      
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }
      @scheduler.on_message(BuildCompleteEvent.new(@build))
      @mock_executor.__verify
    end
    
    def test_build_is_sheduled_on_first_available_executor_only
      only_available_executor = MockIt::Mock.new
      @scheduler.add_executor(only_available_executor)
    
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| false }
      only_available_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      only_available_executor.__expect(:can_execute?) {|b| true }
      only_available_executor.__expect(:put) { |o| assert_same(@build, o) }

      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_queued_build_is_scheduled_when_executor_is_available
      busy_build = Build.new("busy")

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); true }
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|build| assert_same(@build, build); true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      @scheduler.on_message(BuildRequestEvent.new(@build))
      @scheduler.on_message(BuildCompleteEvent.new(busy_build))      
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_doesnt_schedule_build_for_project_that_is_already_building
      project_build1 = Build.new("project")

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |b| assert_same(project_build1, b) }
      @mock_executor.__expect(:building_project?) {|project_name| assert_equal("project", project_name); true }

      @scheduler.on_message(BuildRequestEvent.new(project_build1))
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_three_requests_from_three_different_projects_are_queued_and_then_scheduled
      project1_build = Build.new("project1")
      project2_build = Build.new("project2")
      
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project1", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(project1_build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project2", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(project2_build, o) }

      @scheduler.on_message(BuildRequestEvent.new(@build))
      @scheduler.on_message(BuildRequestEvent.new(project1_build))
      @scheduler.on_message(BuildRequestEvent.new(project2_build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_request_from_same_project_twice_removes_earlier_entries_in_queue
      build2 = Build.new("project")
      build3 = Build.new("project")

      @mock_executor.__expect(:building_project?) {|project_name| 
        assert_equal("project", project_name)
        false
      }
      @mock_executor.__expect(:can_execute?) { true }
      @mock_executor.__expect(:put) {|b| assert_same(@build, b)}
      @mock_executor.__expect(:building_project?) {|project_name| 
        assert_equal("project", project_name)
        true
      }
      @mock_executor.__expect(:building_project?) {|project_name| 
        assert_equal("project", project_name)
        true
      }

      @scheduler.on_message(BuildRequestEvent.new(@build))
      @scheduler.on_message(BuildRequestEvent.new(build2))
      @scheduler.on_message(BuildRequestEvent.new(build3))
      
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_quiet_period_can_be_specified_per_build
      @build.config["quiet_period"] = 1
      @scheduler.on_message(BuildRequestEvent.new(@build))

      @mock_hub.__verify
      @mock_executor.__verify

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      sleep(2)

      @mock_executor.__verify
    end
  end
end
