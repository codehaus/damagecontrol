require 'test/unit'
require 'mockit'
require 'xmlrpc/server'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/LogWriter'

module DamageControl

  class BuildExecutorBuildSchedulerLogWriterIntegrationTest < Test::Unit::TestCase
    
    include HubTestHelper

    def setup
      create_hub
      @executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub))
      @scheduler = BuildScheduler.new(hub)
      @scheduler.default_quiet_period = 0
      @scheduler.add_executor(@executor)
      @build = Build.new("test", {"build_command_line" => "echo 'Hello'"})
      LogWriter.new(hub, '/tmp')
    end

    def test_executor_scheduler_and_logwriter_plays_along_nicely
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      @executor.process_next_scheduled_build
    end

  end

end 
