require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/FileSystem'
require 'damagecontrol/Slot'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor
  
    include Threading
    
    attr_reader :current_build
    attr_reader :builds_dir
    attr_writer :checkout
    
    attr_accessor :last_build_request

    def initialize(channel, builds_dir = "builds", scm = DefaultSCMRegistry.new)
      @channel = channel
      @builds_dir = builds_dir
      @scm = scm
      @filesystem = FileSystem.new
      @checkout = true
      @scheduled_build_slot = Slot.new
    end
    
    def checkout
      @scm.checkout(scheduled_build.scm_spec, project_base_dir) do |progress| 
        report_progress(progress)
      end
    end

    def execute
      @filesystem.makedirs(project_base_dir)
      @filesystem.chdir(project_base_dir)
 
      IO.foreach("|#{scheduled_build.build_command_line} 2>&1") do |line|
        report_progress(line)
      end
      scheduled_build.successful = ($? == 0)
    end
 
    def project_base_dir
      "#{@builds_dir}/#{scheduled_build.project_name}"
    end
    
    def checkout?
      @checkout && !scheduled_build.scm_spec.nil?
    end
    
    def scheduled_build
      if busy? then @scheduled_build_slot.get else nil end
    end
  
    def schedule_build(build)
      @scheduled_build_slot.set(build)
    end
    
    def busy?
      !@scheduled_build_slot.empty?
    end
    
    def build_started
      scheduled_build.start_time = Time.now.to_i
      @channel.publish_message(BuildStartedEvent.new(scheduled_build))
    end
    
    def build_complete
      scheduled_build.end_time = Time.now.to_i
      @channel.publish_message(BuildCompleteEvent.new(scheduled_build))

      # atomically frees the slot, we are now no longer busy
      @scheduled_build_slot.clear
    end

    # will block until scheduled build becomes available
    def next_scheduled_build
      @scheduled_build_slot.get
    end
    
    def process_next_scheduled_build
      next_scheduled_build
      begin
      	build_started
        checkout if checkout?
        execute
      rescue Exception => e
        stacktrace = e.backtrace.join("\n")
        report_progress("Build failed due to: #{stacktrace}")
        current_build.successful = false
      ensure
        build_complete
      end
    end
    
    def start
      new_thread do
        while(true)
          protect { process_next_scheduled_build }
        end
      end
    end
    
    def report_progress(progress)
      @channel.publish_message(BuildProgressEvent.new(current_build, progress))
    end

  end
  
end
