require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/core/DependentBuildTrigger'

module DamageControl

  class DependentBuildTriggerTest < Test::Unit::TestCase
  
    include HubTestHelper
  
    def test_triggers_dependent_build_after_build_completes
      create_hub

      timestamp = "19770615120000"
      build = Build.new("damagecontrolled", timestamp, {
        "dependent_projects" => ["dep_project_1", "dep_project_2"]
        })
      build.status = Build::SUCCESSFUL
      dep_build_1 = Build.new("dep_project_1", timestamp)

      mock_project_config_repository = MockIt::Mock.new
      mock_project_config_repository.__expect(:create_build) do |project_name, dep_timestamp| 
        assert_equal("dep_project_1", project_name)
        assert_equal(timestamp, dep_timestamp)
        dep_build_1
      end
      mock_project_config_repository.__expect(:create_build) do |project_name, timestamp| 
        assert_equal("dep_project_2", project_name) 
        Build.new(project_name)
      end

      DependentBuildTrigger.new(hub, mock_project_config_repository)

      hub.publish_message(BuildCompleteEvent.new(build))

      assert_message_types_from_hub([BuildCompleteEvent, BuildRequestEvent, BuildRequestEvent])
      assert_same(dep_build_1, messages_from_hub[-2].build)
    end

    def test_does_not_trigger_on_failed_build
      create_hub
      build = Build.new("damagecontrolled", Time.new, {
        "dependent_projects" => ["dep_project_1", "dep_project_2"]
        })
      build.status = Build::FAILED
      DependentBuildTrigger.new(hub, MockIt::Mock.new)
      
      hub.publish_message(BuildCompleteEvent.new(build))
      
      assert_message_types_from_hub([BuildCompleteEvent])
    end
  end
end
