require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/BuildScheduler'

module DamageControl

  class BuildSchedulerTest < Test::Unit::TestCase
  
    include FileUtils
    include MockIt
    
    def setup
      # AWFUL hack to get around a race condition i couldn't solve (AH)
      sleep(1.5)
      @mock_hub = new_mock
      @mock_hub.__expect(:add_consumer) {|consumer| assert(consumer.is_a?(BuildScheduler))}

      @build = Build.new("project")
      @build.dc_creation_time = Time.new.utc
      @project_config_repository = new_mock

      @scheduler = BuildScheduler.new(@mock_hub, @project_config_repository, 0)

      @mock_executor = new_mock
      @scheduler.add_executor(@mock_executor)
    end
    
    def test_build_is_scheduled_on_available_executor
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| assert_same(@build, b) ; true }
      @mock_executor.__expect(:put) {|b| assert_same(@build, b) }
      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
    end
    
    def test_build_is_not_executed_on_busy_executor
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| false }
      @scheduler.on_message(CheckedOutEvent.new("projectA", Time.new, true))
      
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }
      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
    end
    
    def test_build_is_sheduled_on_first_available_executor_only
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      only_available_executor = new_mock
      @scheduler.add_executor(only_available_executor)
    
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| false }
      only_available_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      only_available_executor.__expect(:can_execute?) {|b| true }
      only_available_executor.__expect(:put) { |o| assert_same(@build, o) }

      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
    end
    
    def test_queued_build_is_scheduled_when_executor_is_available
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      busy_build = Build.new("busy")
      busy_build.dc_creation_time = Time.now.utc

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); true }
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|build| assert_same(@build, build); true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
      @scheduler.on_message(BuildCompleteEvent.new(busy_build))      
    end
    
    def test_doesnt_schedule_build_for_project_that_is_already_building
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      project_build1 = Build.new("project")
      project_build1.dc_creation_time = Time.new.utc

      @project_config_repository.__expect(:create_build) {|project_name| project_build1}
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |b| assert_same(@build, b) }
      @mock_executor.__expect(:building_project?) {|project_name| assert_equal("project", project_name); true }

      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
    end
    
    def test_three_requests_from_three_different_projects_are_queued_and_then_scheduled
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      project1_build = Build.new("project1")
      project1_build.dc_creation_time = Time.new.utc
      project2_build = Build.new("project2")
      project2_build.dc_creation_time = Time.new.utc
      
      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project1", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(project1_build, o) }

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project2", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(project2_build, o) }

      @project_config_repository.__expect(:create_build) {|project_name| project1_build}
      @project_config_repository.__expect(:create_build) {|project_name| project2_build}

      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
      @scheduler.on_message(CheckedOutEvent.new("project1", Time.new, true))
      @scheduler.on_message(CheckedOutEvent.new("project2", Time.new, true))
    end
    
    def test_request_from_same_project_twice_removes_earlier_entries_in_queue
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      build2 = Build.new("project")
      build2.dc_creation_time = Time.new.utc
      build3 = Build.new("project")
      build3.dc_creation_time = Time.new.utc

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

      @project_config_repository.__expect(:create_build) {|project_name| build2}
      @project_config_repository.__expect(:create_build) {|project_name| build3}

      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))
      @scheduler.on_message(CheckedOutEvent.new("project", Time.new+1, true))
      @scheduler.on_message(CheckedOutEvent.new("project", Time.new+2, true))
      
    end
    
    def test_quiet_period_can_be_specified_per_build
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      @build.config["quiet_period"] = 1
      @scheduler.on_message(CheckedOutEvent.new("project", Time.new, true))

      @mock_executor.__expect(:building_project?) { |project_name| assert_equal("project", project_name); false }
      @mock_executor.__expect(:can_execute?) {|b| true }
      @mock_executor.__expect(:put) { |o| assert_same(@build, o) }

      sleep(2)
    end
    
    def test_should_not_schedule_build_when_no_changes_and_not_forced
      @scheduler.on_message(CheckedOutEvent.new("project", nil, false))
    end

    def test_should_schedule_build_when_no_changes_but_forced
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      @mock_executor.__expect(:building_project?) { false }
      @mock_executor.__expect(:can_execute?) { true }
      @mock_executor.__expect(:put)

      @scheduler.on_message(CheckedOutEvent.new("project", nil, true))
    end

    def test_should_schedule_build_when_changes_but_not_forced
      @project_config_repository.__expect(:create_build) {|project_name| @build}
      @mock_executor.__expect(:building_project?) { false }
      @mock_executor.__expect(:can_execute?) { true }
      @mock_executor.__expect(:put)

      @scheduler.on_message(CheckedOutEvent.new("project", nil, true))
    end
  end
end
