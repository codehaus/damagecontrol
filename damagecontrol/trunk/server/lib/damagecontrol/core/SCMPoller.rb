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
      logger.info("starting #{self}")
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
      logger.info("polling project #{project_name}")
      checkout_dir = @project_directories.checkout_dir(project_name)

      last_commit_time = @build_history_repository.last_commit_time(project_name)
      from_time = last_commit_time ? last_commit_time + 1 : Time.epoch

      changesets = nil
      # check for any changes since last completed build and now
      if(scm.uptodate?(checkout_dir, from_time))
        logger.info("#{project_name} seems to be uptodate")
        return
      else
        logger.info("Local working copy for #{project_name} is not uptodate, getting changesets and requesting build")
        changesets = scm.changesets(checkout_dir, from_time)
        if(changesets.empty? && last_commit_time)
          logger.info("WARNING!!!! we decided #{project_name} was not uptodate, yet there were no changes. This is contradictory!!")
          return
        end
      end
      request_build(project_name, changesets)
    end
    
    def request_build(project_name, changesets=nil)
      build = @project_config_repository.create_build(project_name)
      build.changesets = changesets if changesets # set this to avoid BuildExecutor from having to parse the log again
      @hub.put(BuildRequestEvent.new(build))
    end
  end
end