require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/scm/AbstractSCM'

module DamageControl

  class BuildExecutorBuildSchedulerLogWriterIntegrationTest < Test::Unit::TestCase
    
    include HubTestHelper
    include FileUtils

    def setup
      @basedir = new_temp_dir("integration")
      create_hub
      @executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub))
      @scheduler = BuildScheduler.new(hub)
      @scheduler.default_quiet_period = 0
      @scheduler.add_executor(@executor)
      @build = Build.new("test", Time.now, {"build_command_line" => "echo 'Hello'"})
      @build.scm = StubSCM.new(@basedir)
      LogWriter.new(hub, ProjectDirectories.new(@basedir))
    end

    def test_executor_scheduler_and_logwriter_plays_along_nicely
      hub.publish_message(BuildRequestEvent.new(@build))
      @scheduler.force_tick
      @executor.process_next_scheduled_build
      assert(File.exists?("#{@basedir}/test/log"))
      assert(!Dir["#{@basedir}/test/log/*.log"].empty?)
    end

  end
  
  class StubSCM < AbstractSCM
    def initialize(basedir)
      super("checkout_dir" => basedir)
    end
  end

end 
