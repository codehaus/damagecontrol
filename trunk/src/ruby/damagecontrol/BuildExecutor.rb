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
      @scm.checkout(current_build.scm_spec, project_base_dir) do |progress| 
        report_progress(progress)
      end
    end

    def execute
      @filesystem.makedirs(project_base_dir)
      @filesystem.chdir(project_base_dir)
 
      start_time = Time.now.to_i
      IO.foreach("|#{current_build.build_command_line} 2>&1") do |line|
        report_progress(line)
      end
      end_time = Time.now.to_i
      current_build.successful = ($? == 0)
      current_build.build_duration_seconds = (end_time - start_time)
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
    
    def build_done
      @channel.publish_message(BuildCompleteEvent.new(current_build))
      @scheduled_build_slot.clear
    end

    def next_scheduled_build
      @scheduled_build_slot.get
    end
    
    def process_next_scheduled_build
      @current_build = next_scheduled_build
      begin
        checkout if checkout?
        execute
      rescue Exception => e
        stacktrace = e.backtrace.join("\n")
        report_progress("Build failed due to: #{stacktrace}")
        current_build.successful = false
      ensure
        build_done
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
