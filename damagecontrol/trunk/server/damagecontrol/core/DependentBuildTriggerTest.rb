require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/DependentBuildTrigger'

module DamageControl

  class DependentBuildTriggerTest < Test::Unit::TestCase
  
    include MockIt
  
    def test_triggers_dependent_build_after_build_completes
      build = Build.new("damagecontrolled", {
        "dependent_projects" => ["dep_project_1", "dep_project_2"]
        })
      build.status = Build::SUCCESSFUL

      mock_project_config_repository = new_mock

      dep_build_1 = Build.new("dep_project_1")
      mock_project_config_repository.__expect(:create_build) do |project_name| 
        assert_equal("dep_project_1", project_name)
        dep_build_1
      end

      dep_build_2 = Build.new("dep_project_2")
      mock_project_config_repository.__expect(:create_build) do |project_name| 
        assert_equal("dep_project_2", project_name) 
        dep_build_2
      end

      hub = new_mock
      hub.__expect(:add_consumer) do |subscriber|
        assert(subscriber.is_a?(DependentBuildTrigger))
      end
      dbt = DependentBuildTrigger.new(hub, mock_project_config_repository)

      hub.__expect(:put) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert_same(dep_build_1, message.build)
      end
      hub.__expect(:put) do |message|
        assert(message.is_a?(BuildRequestEvent))
        assert_same(dep_build_2, message.build)
      end
      dbt.put(BuildCompleteEvent.new(build))

    end

    def test_does_not_trigger_on_failed_build
      build = Build.new("damagecontrolled", {
        "dependent_projects" => ["dep_project_1", "dep_project_2"]
        })
      build.status = Build::FAILED

      hub = new_mock
      hub.__expect(:add_consumer) do |subscriber|
        assert(subscriber.is_a?(DependentBuildTrigger))
      end

      dbt = DependentBuildTrigger.new(hub, new_mock)
      dbt.put(BuildCompleteEvent.new(build))
    end
  end
end
