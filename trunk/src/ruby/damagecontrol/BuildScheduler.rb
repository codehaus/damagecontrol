require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/BuildExecutor'

module DamageControl

  class BuildScheduler < AsyncComponent
    attr_reader :executors
    attr_reader :build_queue
    
    def initialize(hub)
      super(hub)
      @executors = []
      reset_build_queue
    end
  
    def add_executor(executor)
      executors<<executor
    end
    
    def find_available_executor
      executors.find {|executor|  !executor.busy? }
    end
    
    def find_build_for_project(project_name)
      build_queue.find{|qd_build| qd_build.project_name == project_name }
    end
    
    def project_scheduled?(project_name)
      !find_build_for_project(project_name).nil?
    end
    
    def enqueue_build(build)
      qd_build = find_build_for_project(build.project_name)
      
      if qd_build.nil?
        build_queue<<build
      elsif qd_build.timestamp_as_i < build.timestamp_as_i
        build_queue.delete(qd_build)
        build_queue<<build
      end
    end
    
    def schedule_build(build)
      available_executor = find_available_executor
      if quiet_period_elapsed?(build) && !available_executor.nil?
        available_executor.schedule_build(build)
      else
        # not quite time for you, back on the queue
        enqueue_build(build)
      end
    end
    
    def default_quiet_period
      0
    end
    
    def quiet_period(build)
      if build.quiet_period.nil? 
        default_quiet_period
      else 
        build.quiet_period
      end
    end
    
    def quiet_period_elapsed?(build)
      current_time >= build.timestamp_as_i + quiet_period(build)
    end
    
    def reset_build_queue
      @build_queue = []
    end
    
    def schedule_queued_builds
      build_queue = self.build_queue.dup
      reset_build_queue
      build_queue.each do |build|
        schedule_build(build)
      end
    end
    
    def tick(time)
      process_messages
      schedule_queued_builds
    end
    
    def process_message(event)
      if event.is_a?(BuildRequestEvent)
        schedule_build(event.build)
      end
    end
    
    def start
      super
      executors.each {|executor| executor.start}
    end
    
  end

end 