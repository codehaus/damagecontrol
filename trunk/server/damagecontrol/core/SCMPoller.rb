require 'pebbles/Clock'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'

module DamageControl


  # This class checks for a "polling" property in each project's config.
  # If it is defined, and equals true, then it will poll using the default polling interval.
  # If it is defined, and is an integer, then it will poll at that interval. (If the project
  # specific interval is shorter than the default interval, it will have no effect,
  # since ticks only occur at the default interval.
  #
  class SCMPoller < Pebbles::Clock
    include Logging
    
    def initialize(hub, polling_interval, project_config_repository, build_scheduler, checkout_manager)
      super(polling_interval)
      @polling_interval = polling_interval
      @hub = hub
      @polling_interval = polling_interval
      @project_config_repository = project_config_repository
      @build_scheduler = build_scheduler
      @checkout_manager = checkout_manager
      @poll_times = {}
    end
    
    def start
      logger.info("starting poller #{self}")
      super
    end
  
    def tick(time)
      @project_config_repository.project_names.each do |project_name| 
        now = Time.at(time)
        if should_poll?(project_name, now)
          @poll_times[project_name] = now
          poll_project(project_name)
        end
      end
    end
    
    def poll_project(project_name)
      changesets_or_last_commit_time = @checkout_manager.checkout(project_name)
      if(changesets_or_last_commit_time)
        build = @project_config_repository.create_build(project_name)
        if(changesets_or_last_commit_time.is_a?(ChangeSets))
          build.changesets = changesets_or_last_commit_time
        end
        @hub.publish_message(BuildRequestEvent.new(build))        
      end
    end

  private

    def should_poll?(project_name, time)
      return false if @build_scheduler.project_scheduled?(project_name)
      return false if @build_scheduler.project_building?(project_name)

      project_config = @project_config_repository.project_config(project_name)
      polling_interval = project_config["polling"]
      if(polling_interval.is_a?(FalseClass) || polling_interval.is_a?(TrueClass))
        # old format
        return polling_interval
      else
        interval =  polling_interval || @polling_interval
        last_poll = @poll_times[project_name] || Time.utc(1970)
        required_time = last_poll + interval
        return required_time < time
      end
    end
    
  end
end