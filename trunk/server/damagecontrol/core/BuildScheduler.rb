require 'pebbles/Clock'
require 'pebbles/Space'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/util/Logging'

module DamageControl

  class PendingBuild < Pebbles::Countdown
    attr_accessor :build
  
    def initialize(quiet_period, build_scheduler)
      super(quiet_period)
      @build_scheduler = build_scheduler
    end
    
    def tick(time)
      @build_scheduler.done(self)
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
      @pending_builds = {}
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
    
    def done(pending_build)
      unless(project_building?(pending_build.build.project_name))
        # find an available executor
        executor = @executors.find {|executor| !executor.busy? }
        if(executor)
          @pending_builds.delete(pending_build.build.project_name)
          executor.put(pending_build.build)
        else
          # If no executors are available, just restart the quiet period.
          pending_build.start
        end
      end
    end

    def exception(e)
      @exception_logger.exception(e) 
    end
    
    def build_queue
      queue.collect { |build_request_event| build_request_event.build }
    end

    def project_building?(project_name)
      @executors.find {|e| e.building_project?(project_name) }
    end

  private
  
    def schedule_build(build)
      pending_build = @pending_builds[build.project_name]
      if(pending_build.nil?)
        pending_build = PendingBuild.new(quiet_period(build), self)
        @pending_builds[build.project_name] = pending_build
      end
      pending_build.build = build
      pending_build.start
    end
    
    def quiet_period(build)
      build.quiet_period ? build.quiet_period : @quiet_period
    end
    
  end

end
