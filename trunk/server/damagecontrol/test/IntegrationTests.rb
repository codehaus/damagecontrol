require 'test/unit'
require 'pebbles/mockit'
require 'xmlrpc/server'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/scm/AbstractSCM'

module DamageControl

  class ProjectConfigRepositoryBuildExecutorBuildSchedulerLogWriterIntegrationTest < Test::Unit::TestCase
    
    include HubTestHelper
    include FileUtils

    def setup
      @basedir = new_temp_dir("integration")
      create_hub
      @executor = BuildExecutor.new(hub, BuildHistoryRepository.new(hub))
      @scheduler = BuildScheduler.new(hub)
      @scheduler.default_quiet_period = 0
      @scheduler.add_executor(@executor)
      @project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(@basedir), nil)
      @project_config_repository.new_project("test")
      @project_config_repository.modify_project_config("test",
        {"build_command_line" => "echo 'Hello'", "scm_type" => StubSCM.name })
      @build = @project_config_repository.create_build("test", Time.now)
      LogWriter.new(hub)
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
  end

end 
