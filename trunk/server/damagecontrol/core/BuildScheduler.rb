require 'pebbles/Clock'
require 'pebbles/Space'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl

  # This class is responsible for scheduling builds among several BuildExecutors
  class BuildScheduler < Pebbles::Space

    include Logging
  
    DEFAULT_QUIET_PERIOD = 5 # seconds
    
    attr_reader :executors
    attr_reader :default_quiet_period
    attr_reader :build_queue
    
    def initialize(channel, project_config_repository, default_quiet_period=DEFAULT_QUIET_PERIOD, exception_logger=nil)
      super
      @channel = channel
      @channel.add_consumer(self) unless @channel.nil?

      @project_config_repository = project_config_repository
      @default_quiet_period = default_quiet_period
      @exception_logger = exception_logger

      @executors = []
      @build_queue = []
    end
  
    def on_message(event)
      if event.is_a?(CheckedOutEvent)
        # We only want to build if this is a forced build or if there are changes
        if(event.force_build || !event.changesets_or_last_commit_time.nil?)
          build = @project_config_repository.create_build(event.project_name)
          if(event.changesets_or_last_commit_time.is_a?(ChangeSets))
            build.changesets = event.changesets_or_last_commit_time
          end

          build.status = Build::QUEUED
          if(!event.changesets_or_last_commit_time.nil?)
            logger.info("Scheduling build for #{event.project_name} as there were changes.")
          else
            logger.info("Scheduling build for #{event.project_name} as it was forced.")
          end
          schedule_build(build)
        else
          logger.info("Not scheduling build for #{event.project_name} as there were no changes and the build isn't forced.")
        end
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
      executors.find {|e| e.building_project?(project_name) }
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
      executors.find {|e| e.can_execute?(build) }
    end

    # try to execute build, taking quiet period and available suitable executors into consideration
    def try_to_execute_build(build)
      return if project_building?(build.project_name)
      return unless quiet_period_elapsed?(build)
      
      executor = find_available_executor(build)
      return unless executor
      
      build_queue.delete(build)
      executor.put(build)
    end
    
    def quiet_period_elapsed?(build)
      time_in_queue(build) > quiet_period(build)
    end
    
    def time_in_queue(build)
      Time.now.utc - build.dc_creation_time
    end
    
    # try to execute all builds in build queue
    def try_to_execute_builds
      build_queue.each {|b| try_to_execute_build(b) }
    end
    
    # called when the quiet period of any build has elapsed
    def quiet_period_elapsed
      try_to_execute_builds
    end
    
    def schedule_build(build)
      build_queue.delete_if{|b| b.project_name == build.project_name}
      build_queue << build
      
      c = Pebbles::Countdown.new(quiet_period(build)) do |time|
        begin
          quiet_period_elapsed
        rescue
          exception($!)
        end
      end
      c.start
    end
    
    def quiet_period(build)
      build.quiet_period ? build.quiet_period : @default_quiet_period
    end
    
  end

end
