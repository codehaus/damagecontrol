require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/BuildHistoryRepository'

module DamageControl

  class BuildExecutorBuildSchedulerLogWriterIntegrationTest < Test::Unit::TestCase
    
    include HubTestHelper
    include FileUtils

    def setup
      basedir = new_temp_dir("integration")
      create_hub
      @executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub), basedir)
      @scheduler = BuildScheduler.new(hub)
      @scheduler.default_quiet_period = 0
      @scheduler.add_executor(@executor)
      @build = Build.new("test", Time.now, {"build_command_line" => "echo 'Hello'"})
      LogWriter.new(hub, basedir)
    end

    def test_executor_scheduler_and_logwriter_plays_along_nicely
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      @executor.process_next_scheduled_build
    end

  end

end 
