require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/DependentBuildTrigger'

module DamageControl

  class DependentBuildTriggerTest < Test::Unit::TestCase
  
    def test_triggers_dependent_build_after_build_completes
      timestamp = "19770615120000"
      build = Build.new("damagecontrolled", timestamp, {
        "dependent_projects" => ["dep_project_1", "dep_project_2"]
        })
      build.status = Build::SUCCESSFUL

      mock_project_config_repository = MockIt::Mock.new

      dep_build_1 = Build.new("dep_project_1", timestamp)
      mock_project_config_repository.__expect(:create_build) do |project_name, dep_timestamp| 
        assert_equal("dep_project_1", project_name)
        assert_equal(timestamp, dep_timestamp)
        dep_build_1
      end

      dep_build_2 = Build.new("dep_project_2", timestamp)
      mock_project_config_repository.__expect(:create_build) do |project_name, timestamp| 
        assert_equal("dep_project_2", project_name) 
        dep_build_2
      end

      hub = MockIt::Mock.new
      hub.__expect(:add_subscriber) do |subscriber|
        assert(subscriber.is_a?(DependentBuildTrigger))
      end
      dbt = DependentBuildTrigger.new(hub, mock_project_config_repository)

      hub.__expect(:publish_message) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert_same(dep_build_1, message.build)
      end
      hub.__expect(:publish_message) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert_same(dep_build_2, message.build)
      end
      dbt.put(BuildCompleteEvent.new(build))

#      assert_message_types_from_hub([BuildCompleteEvent, BuildRequestEvent, BuildRequestEvent])
      
      mock_project_config_repository.__verify
      hub.__verify
    end

    def test_does_not_trigger_on_failed_build
      build = Build.new("damagecontrolled", Time.new, {
        "dependent_projects" => ["dep_project_1", "dep_project_2"]
        })
      build.status = Build::FAILED

      hub = MockIt::Mock.new
      hub.__expect(:add_subscriber) do |subscriber|
        assert(subscriber.is_a?(DependentBuildTrigger))
      end

      dbt = DependentBuildTrigger.new(hub, MockIt::Mock.new)
      dbt.put(BuildCompleteEvent.new(build))
      
      hub.__verify
    end
  end
end
