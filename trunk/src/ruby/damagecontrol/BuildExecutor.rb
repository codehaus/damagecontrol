require 'damagecontrol/Build'
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
      current_build.status = Build::CHECKING_OUT

      @scm.checkout(current_build.scm_spec, project_base_dir) do |progress| 
        report_progress(progress)
      end
    end

    def execute
      current_build.status = Build::BUILDING

      @filesystem.makedirs(project_base_dir)
      @filesystem.chdir(project_base_dir)
 
      IO.foreach("|#{current_build.build_command_line} 2>&1") do |line|
        report_progress(line)
      end
      if($? == 0)
        current_build.status = Build::SUCCESSFUL
      else
        current_build.status = Build::FAILED
      end
    end
 
    def project_base_dir
      "#{@builds_dir}/#{current_build.project_name}"
    end
    
    def checkout?
      @checkout && !current_build.scm_spec.nil?
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
      current_build.start_time = Time.now.to_i
      @channel.publish_message(BuildStartedEvent.new(current_build))
    end
    
    def build_complete
      current_build.end_time = Time.now.to_i
      @channel.publish_message(BuildCompleteEvent.new(current_build))

      # atomically frees the slot, we are now no longer busy
      @scheduled_build_slot.clear
    end

    # will block until scheduled build becomes available
    def next_scheduled_build
      @scheduled_build_slot.get
    end
    
    def current_build
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
        current_build.status = Build::SUCCESSFUL
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
