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
    
    def enqueue_build(build)
      build_queue<<build
    end
    
    def schedule_build(build)
      available_executor = find_available_executor
      if available_executor.nil?
        enqueue_build(build)  
      else
        available_executor.schedule_build(build)
      end
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

end