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
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_build_is_not_scheduled_on_busy_executor    
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { true }
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_build_is_sheduled_on_first_available_executor_only
      other_executor = MockIt::Mock.new
      @scheduler.add_executor(other_executor)
    
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { true }
      other_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      other_executor.__expect(:busy?) { false }
      other_executor.__expect(:put) { |o| assert_same(@build, o) }

      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_queued_build_is_scheduled_when_executor_is_available
      other_build = Build.new("other")

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("other", project_name); false }
      @mock_executor.__expect(:busy?) { true }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("other", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(other_build, o) }
    
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @scheduler.on_message(BuildRequestEvent.new(other_build))      
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_doesnt_schedule_build_for_project_that_is_already_building
      project_build1 = Build.new("project")

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(project_build1, o) }
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); true }

      @scheduler.on_message(BuildRequestEvent.new(project_build1))
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_three_requests_from_three_different_projects_are_queued_and_then_scheduled
    
      project1_build = Build.new("project1")
      project2_build = Build.new("project2")
      
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project1", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(project1_build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project2", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(project2_build, o) }

      @scheduler.on_message(BuildRequestEvent.new(@build))
      @scheduler.on_message(BuildRequestEvent.new(project1_build))
      @scheduler.on_message(BuildRequestEvent.new(project2_build))
      @mock_hub.__verify
      @mock_executor.__verify
    end
    
    def test_request_from_same_project_twice_removes_earlier_entries_in_queue
      mock_exception_logger = MockIt::Mock.new
      mock_hub = MockIt::Mock.new
      mock_hub.__expect(:add_consumer) {|consumer| assert(consumer.is_a?(BuildScheduler))}

      scheduler = BuildScheduler.new(mock_hub, 1, mock_exception_logger)
      mock_executor = MockIt::Mock.new
      scheduler.add_executor(mock_executor)
    
      build2 = Build.new("project")
      build3 = Build.new("project")

      mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      mock_executor.__expect(:busy?) { false }
      mock_executor.__expect(:put) { |o| assert_same(build3, o) }

      scheduler.on_message(BuildRequestEvent.new(@build))
      scheduler.on_message(BuildRequestEvent.new(build2))
      scheduler.on_message(BuildRequestEvent.new(build3))

      sleep(2)
      
      mock_hub.__verify
      mock_executor.__verify
      mock_exception_logger.__verify
    end
    
    def test_quiet_period_can_be_specified_per_build
      @build.config["quiet_period"] = 1
      @scheduler.on_message(BuildRequestEvent.new(@build))

      @mock_hub.__verify
      @mock_executor.__verify

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:busy?) { false }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      sleep(2)

      @mock_executor.__verify
    end
    
    def test_build_queue_is_sorted_according_to_elapsed_quiet_period_next_build_first
      @build.config["quiet_period"] = 100
      build2 = Build.new("project2")
      build2.config["quiet_period"] = 100
      earliest_build = Build.new("earliest_project")
      earliest_build.config["quiet_period"] = 2
      @scheduler.on_message(BuildRequestEvent.new(@build))
      @scheduler.on_message(BuildRequestEvent.new(build2))
      @scheduler.on_message(BuildRequestEvent.new(earliest_build))
      
      assert_equal([earliest_build, @build, build2], @scheduler.build_queue)
    end
  end
end
