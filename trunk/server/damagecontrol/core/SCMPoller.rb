require 'pebbles/Clock'
require 'pebbles/TimeUtils'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'

require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/core/BuildScheduler'

module DamageControl


  # This class checks for a "polling" property in each project's config.
  # If it is defined, and equals true, then it will poll using the default polling interval.
  # If it is defined, and is an integer, then it will poll at that interval. (If the project
  # specific interval is shorter than the default interval, it will have no effect,
  # since ticks only occur at the default interval.
  #
  class SCMPoller < Pebbles::Clock
    include Logging
    include Pebbles::TimeUtils
    
    def initialize(channel, polling_interval, project_config_repository, build_scheduler)
      super(polling_interval)
      @polling_interval = polling_interval
      @channel = channel
      @polling_interval = polling_interval
      @project_config_repository = project_config_repository
      @build_scheduler = build_scheduler
      @poll_times = {}
    end
    
    def to_s
      "#{super} polling_interval: #{duration_as_text(@polling_interval)}"
    end
    
    def start
      logger.info("starting poller #{self}")
      super
    end
  
    def tick(time)
      logger.info("tick #{time.to_human}")
      @project_config_repository.project_names.each do |project_name|        
        if(@poll_times[project_name].nil?)
          @poll_times[project_name] = Time.new.utc
        end

        if should_poll?(project_name, time)
          @poll_times[project_name] = time
          @channel.put(DoCheckoutEvent.new(project_name, false))
          logger.info("Requested checkout for #{project_name}")
        else
          logger.info("Not requesting checkout for #{project_name}. It isn't time yet.")
        end
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
        should_poll = polling_interval
        return should_poll
      else
        interval =  polling_interval || @polling_interval
        last_poll = @poll_times[project_name]
        required_time = last_poll + interval
        return required_time < time
      end
    end
    
  end
end