require 'pebbles/Clock'
require 'pebbles/Space'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl

  class BuildScheduler < Pebbles::Space

    include Logging
  
    DEFAULT_QUIET_PERIOD = 5 # seconds
    
    attr_reader :executors
    attr_reader :default_quiet_period
    attr_reader :build_queue
    
    def initialize(multicast_space, default_quiet_period=DEFAULT_QUIET_PERIOD, exception_logger=nil)
      super
      @channel = multicast_space
      @channel.add_consumer(self) unless @channel.nil?
      @default_quiet_period = default_quiet_period
      @executors = []
      @build_queue = []
      @exception_logger = exception_logger
    end
  
    def on_message(event)
      if event.is_a?(BuildRequestEvent)
        schedule_build(event.build)
      end
      if event.is_a?(BuildCompleteEvent)
        try_to_execute_builds
      end
    end
    
    def start
      super
      @executors.each {|executor| executor.start}
    end
    
    def add_executor(executor)
      @executors << executor
    end
    
    def exception(e)
      logger.error(format_exception(e))
      @exception_logger.exception(e) if @exception_logger
    end

    def project_building?(project_name)
      executors.find do |e| 
        e.building_project?(project_name) 
      end
    end
    
    def project_scheduled?(project_name)
      build_queue.find{|b| b.project_name == project_name}
    end
    
    def kill_named_executor(executor_name)
      executor = executors.find{|e| e.name == executor_name}
      executor.kill_build_process
    end

  private
    
    def find_available_executor(build)
      executors.find do |e| 
        e.can_execute?(build)
      end
    end

    # try to execute build, taking quiet period and available suitable executors into consideration
    def try_to_execute_build(build)
      if project_building?(build.project_name)
puts "Project is building"
        return
      end

      if(!quiet_period_elapsed?(build))
puts "Quiet period not yet elapsed"
        return
      end
      
      executor = find_available_executor(build)
      if(executor)
        build_queue.delete(build)
        executor.put(build)
      else
puts "No available executor"
      end
    end
    
    def quiet_period_elapsed?(build)
      result = time_in_queue(build) > quiet_period(build)
      result
    end
    
    def time_in_queue(build)
      Time.now.utc - build.dc_creation_time
    end
    
    # try to execute all builds in build queue
    def try_to_execute_builds
      build_queue.each {|b| try_to_execute_build(b) }
    end
        
    def schedule_build(build)
puts "Scheduling build for #{build.project_name}"
      build_queue.delete_if{|b| b.project_name == build.project_name}
      build_queue << build
      
      c = Pebbles::Countdown.new(quiet_period(build)) do |time|
        begin
puts "Trying"
          try_to_execute_build(build)
puts "Tried"
        rescue
puts "Ouch"
          exception($!)
        end
      end
      c.start
    end
    
    def quiet_period(build)
      result = build.quiet_period ? build.quiet_period : @default_quiet_period
puts "QP: #{result}"
      result
    end
    
  end

end
