require 'pebbles/Clock'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'

module DamageControl

  class SCMPoller < Pebbles::Clock
    include Logging
    
    def initialize(hub, polling_interval, project_directories, project_config_repository, build_history_repository, build_scheduler)
      super(polling_interval)
      @hub = hub
      @polling_interval = polling_interval
      @project_directories = project_directories
      @project_config_repository = project_config_repository
      @build_history_repository = build_history_repository
      @build_scheduler = build_scheduler
    end
    
    def start
      logger.info("starting poller #{self}")
      super
    end
  
    def tick(time)
      @project_config_repository.project_names.each {|project_name| poll_project(project_name)}
    end
    
    def should_poll?(project_name)
      return false if @build_scheduler.project_scheduled?(project_name)
      return false if @build_scheduler.project_building?(project_name)
      return false unless project_config(project_name)["polling"]
      true
    end
    
    def project_config(project_name)
      @project_config_repository.project_config(project_name)
    end
    
    def poll_project(project_name)
      return unless should_poll?(project_name)
      scm = @project_config_repository.create_scm(project_name)
      last_completed_build = @build_history_repository.last_completed_build(project_name)
      if last_completed_build.nil?
        # not built yet, just build without checking
        request_build(project_name)
      else
        logger.info("polling project #{project_name}")
        # check for any changes since last completed build and now
        checkout_dir = @project_directories.checkout_dir(project_name)
        if(scm.uptodate?(
          checkout_dir, 
          last_completed_build.scm_commit_time, 
          nil
        ))
          logger.info("no changes in #{project_name}")
        else
          logger.info("changes in #{project_name}, requesting build")
          changesets = scm.changesets(
            checkout_dir, 
            last_completed_build.scm_commit_time, 
            nil
          )
          request_build(project_name, changesets)
        end
      end
    end
    
    def request_build(project_name, changesets=nil)
      build = @project_config_repository.create_build(project_name)
      build.changesets = changesets if changesets # set this to avoid BuildExecutor from having to parse the log again
      @hub.put(BuildRequestEvent.new(build))
    end
  end
end