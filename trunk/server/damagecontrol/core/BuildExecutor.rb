require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/util/Slot'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor
  
    include Threading
    
    attr_reader :current_build
    attr_reader :builds_dir
    
    attr_accessor :last_build_request

    def initialize(channel, build_history, project_directories, scm = DefaultSCMRegistry.new)
      @channel = channel
      @project_directories = project_directories
      @scm = scm
      @scheduled_build_slot = Slot.new
      @build_history = build_history
    end
    
    def checkout
      current_build.status = Build::CHECKING_OUT
      
      @scm.checkout(current_build.scm_spec, project_base_dir) do |progress| 
        report_progress(progress)
      end
    end
    
    def with_working_directory(dir)
      last_dir = Dir.pwd
      FileUtils.mkdir_p(dir)
      begin
        Dir.chdir(dir)
        yield
      ensure
        Dir.chdir(last_dir)
      end
    end

    def execute
      current_build.status = Build::BUILDING

      with_working_directory(project_base_dir) do
        # set up some environment variables the build can use
        ENV["DAMAGECONTROL_CHANGES"] = 
          current_build.modification_set.collect{|m| "\"#{m.path}\"" }.join(" ") unless current_build.modification_set.nil?
          
        IO.foreach("|#{current_build.build_command_line} 2>&1") do |line|
          report_progress(line)
        end
        if($? == 0)
          current_build.status = Build::SUCCESSFUL
        else
          current_build.status = Build::FAILED
        end
      end

    end
 
    def project_base_dir
      @project_directories.checkout_dir(current_build.project_name)
    end
    
    def checkout?
      !current_build.scm_spec.nil?
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
      determine_changeset
      @channel.publish_message(BuildStartedEvent.new(current_build))
    end
    
    def determine_changeset
      # this won't work the first build, so I just skip it 
      # the first time a project is built it will have a changeset of every file in the repository
      # this is almost useless information and there's no point in spending lots of time trying to code around it
      return unless File.exists?(project_base_dir)
      
      begin
        last_successful_build = @build_history.last_succesful_build(current_build.project_name)
        # we have no record of when the last succesful build was made, don't determine the changeset
        # (might be a new project, see comment above)
        return if last_successful_build.nil?
        time_before = last_successful_build.timestamp_as_time
        
        time_after = current_build.timestamp_as_time
        
        current_build.modification_set = 
          @scm.changes(current_build.scm_spec, project_base_dir, time_before, time_after)

      rescue Exception => e
        msg = e.message + e.backtrace.join("\n")
        logger.error "could not determine changeset: #{msg}"
      end
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
        message = e.message + "\n" + e.backtrace.join("\n")
        current_build.error_message = message
        current_build.status = Build::FAILED
        report_progress("Build failed due to: #{message}")
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
