require 'test/unit'
require 'damagecontrol/SelfUpgrader'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'

module DamageControl

  class SelfUpgraderTest < Test::Unit::TestCase
    
    include HubTestHelper

    def setup
      create_hub
      @su = SelfUpgrader.new(hub)
      
      def @su.did_exit?
        @did_exit
      end
      
      def @su.do_exit
        @did_exit = true
      end

    end
    
    def test_exits_on_successful_damagecontrol
      build = Build.new("damagecontrol")
      build.successful = true
      hub.publish_message(BuildCompleteEvent.new(build))
      assert(@su.did_exit?)
    end

    def test_doesnt_exit_on_failed_damagecontrol
      build = Build.new("damagecontrol")
      build.successful = false
      hub.publish_message(BuildCompleteEvent.new(build))
      assert(!@su.did_exit?)
    end

    def test_doesnt_exit_on_successfuk_other_project
      build = Build.new("mustard")
      build.successful = false
      hub.publish_message(BuildCompleteEvent.new(build))
      assert(!@su.did_exit?)
    end
  end
    
end
