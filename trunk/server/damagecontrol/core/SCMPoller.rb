require 'pebbles/Clock'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'

module DamageControl

  class SCMPoller < Pebbles::Clock
    include Logging
    
    def initialize(hub, polling_interval, project_config_repository, build_history_repository, build_scheduler)
      super(polling_interval)
      @hub = hub
      @polling_interval = polling_interval
      @project_config_repository = project_config_repository
      @build_history_repository = build_history_repository
      @build_scheduler = build_scheduler
    end
    
    def start
      logger.info("starting poller #{self}")
      super
    end
  
    def tick(time)
      @project_config_repository.project_names.each {|project_name| poll_project(project_name, Time.at(time))}
    end
    
    def should_poll?(project_name, time)
      return false if @build_scheduler.project_scheduled?(project_name)
      return false if @build_scheduler.project_building?(project_name)
      return false unless project_config(project_name)["polling"]
      true
    end
    
    def project_config(project_name)
      @project_config_repository.project_config(project_name)
    end
    
    def poll_project(project_name, time)
      return unless should_poll?(project_name, time)
      scm = @project_config_repository.create_scm(project_name)
      last_completed_build = @build_history_repository.last_completed_build(project_name)
      if last_completed_build.nil?
        # not built yet, just build without checking
        request_build(project_name, time)
      else
        logger.info("polling project #{project_name}")
        # check for any changes since last completed build and now
        changesets = scm.changesets(last_completed_build.timestamp_as_time, time)
        if changesets.empty?
          logger.info("no changes in #{project_name}")
        else
          logger.info("changes in #{project_name}, requesting build")
          request_build(project_name, time, changesets)
        end
      end
    end
    
    def request_build(project_name, time, changesets=nil)
      build = @project_config_repository.create_build(project_name, time)
      build.changesets = changesets if changesets # set this to avoid BuildExecutor from having to parse the log again
      @hub.publish_message(BuildRequestEvent.new(build))
    end
  end
end