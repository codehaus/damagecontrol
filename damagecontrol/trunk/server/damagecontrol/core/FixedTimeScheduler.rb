require 'pebbles/Clock'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'

# Requests build at a fixed time once a day.
module DamageControl

  class FixedTimeScheduler < Pebbles::Clock
    include Logging
    
    def initialize(hub, tick_interval_seconds, project_config_repository, build_scheduler)
      super(tick_interval_seconds)
      @hub = hub
      @tick_interval_seconds = tick_interval_seconds
      @project_config_repository = project_config_repository
      @build_scheduler = build_scheduler
    end
    
    def start
      logger.info("starting #{self}")
      super
    end
  
    def tick(time)
      @project_config_repository.project_names.each {|project_name| check_schedule(project_name, time)}
    end
    
  private
    
    def check_schedule(project_name, time_now)
      
      return unless has_scheduled_build_time?(project_name)      
      return unless time_now_is_within_scheduled_build_window?(project_name, time_now)
      
      return if @build_scheduler.project_scheduled?(project_name)
      return if @build_scheduler.project_building?(project_name)
      
      request_build(project_name)
    end
    
    def has_scheduled_build_time?(project_name)    
      return false unless project_config(project_name)["fixed_build_time_hhmm"]
      true
    end
    
    def time_now_is_within_scheduled_build_window?(project_name, time_now)
      # time_now - tick_interval_seconds < current_days_schedule_time <= time_now
      hhmm_scheduled_build = project_config(project_name)["fixed_build_time_hhmm"]
      if(hhmm_scheduled_build =~ /(\d+):(\d+)/)
        scheduled_hour = $1.to_i
        scheduled_min = $2.to_i
        current_days_schedule_time = Time.utc(time_now.year, time_now.month, time_now.mday, scheduled_hour, scheduled_min, 0)
        current_days_schedule_time.between?(time_now - @tick_interval_seconds, time_now)
      else
        raise "Bad time format: #{hhmm_scheduled_build}"
      end
    end
    
    def project_config(project_name)
      @project_config_repository.project_config(project_name)
    end

    def request_build(project_name)
      logger.info("requesting build for #{project_name}")
      build = @project_config_repository.create_build(project_name)
      @hub.put(BuildRequestEvent.new(build))
    end
  end
end
