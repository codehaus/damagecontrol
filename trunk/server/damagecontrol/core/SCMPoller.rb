require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Timer'
require 'damagecontrol/util/Logging'

module DamageControl

  class SCMPoller
    include TimerMixin
    include Logging
    
    def initialize(hub, polling_interval, scm_factory, project_config_repository, build_history_repository, build_scheduler)
      @hub = hub
      @polling_interval = polling_interval
      @scm_factory = scm_factory
      @project_config_repository = project_config_repository
      @build_history_repository = build_history_repository
      @build_scheduler = build_scheduler
    end
  
    def tick(time)
      @project_config_repository.project_names.each {|project_name| poll_project(project_name, Time.at(time))}
    end
    
    def polling_interval(project_name)
      # implement project specific polling intervals here
      @polling_interval
    end
    
    def should_poll?(project_name, time)
      return false if @build_scheduler.project_scheduled?(project_name)
      return false if @build_scheduler.project_building?(project_name)
      return false unless project_config(project_name)["polling"]
      return false unless eval(project_config(project_name)["polling"])
      p time.to_i % polling_interval(project_name)
      time.to_i % polling_interval(project_name) == 0
    end
    
    def project_config(project_name)
      @project_config_repository.project_config(project_name)
    end
    
    def poll_project(project_name, time)
      return unless should_poll?(project_name, time)
      scm = @scm_factory.get_scm(project_config(project_name), @project_config_repository.checkout_dir(project_name))
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