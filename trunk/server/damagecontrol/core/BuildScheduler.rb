require 'pebbles/Clock'
require 'pebbles/Space'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/Logging'

module DamageControl

  class QuietPeriodCountDown < Pebbles::Countdown
    attr_accessor :build
  
    def initialize(quiet_period, build_scheduler)
      super(quiet_period)
      @build_scheduler = build_scheduler
    end
    
    def tick(time)
      @build_scheduler.quiet_period_elapsed(self)
    end

    def exception(e)
      @build_scheduler.exception(e)
    end
  end

  class BuildScheduler < AsyncComponent

    include Logging
  
    DEFAULT_QUIET_PERIOD = 5 # seconds
    
    attr_reader :executors
    
    def initialize(hub, quiet_period=DEFAULT_QUIET_PERIOD, exception_logger=nil)
      super(hub)
      @quiet_period = quiet_period
      @executors = []
      @countdowns = {}
      @exception_logger = exception_logger
    end
  
    def process_message(event)
      if event.is_a?(BuildRequestEvent)
        schedule_build(event.build)
      end
    end
    
    def start
      super
      @executors.each {|executor| executor.start}
    end
    
    def add_executor(executor)
      @executors << executor
    end
    
    def quiet_period_elapsed(countdown)
      unless(project_building?(countdown.build.project_name))
        # find an available executor
        executor = @executors.find {|executor| !executor.busy? }
        if(executor)
          @countdowns.delete(countdown.build.project_name)
          executor.put(countdown.build)
        else
          # If no executors are available, just restart the quiet period.
          countdown.start
        end
      end
    end

    def exception(e)
      @exception_logger.exception(e) 
    end
    
    def build_queue
      @countdowns.values.sort {|c1, c2| c1.time_left <=> c2.time_left}.collect {|c| c.build }
    end

    def project_building?(project_name)
      @executors.find {|e| e.building_project?(project_name) }
    end

  private
  
    def schedule_build(build)
      countdown = @countdowns[build.project_name]
      if(countdown.nil?)
        countdown = QuietPeriodCountDown.new(quiet_period(build), self)
        @countdowns[build.project_name] = countdown
      end
      countdown.build = build
      countdown.start
    end
    
    def quiet_period(build)
      build.quiet_period ? build.quiet_period : @quiet_period
    end
    
  end

end
