require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/util/Slot'
require 'damagecontrol/scm/SCMFactory'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor
  
    include Threading
    
    attr_reader :current_build
    attr_reader :builds_dir
    
    attr_accessor :last_build_request

    def initialize(channel, build_history, project_directories, scm_factory=SCMFactory.new)
      @channel = channel
      @build_history = build_history
      @project_directories = project_directories
      @scm_factory = scm_factory

      @scheduled_build_slot = Slot.new
    end
    
    def checkout?
      !current_scm.nil?
    end
    
    def checkout
      return if !checkout?
      
      current_build.status = Build::CHECKING_OUT
      current_scm.checkout(current_build.timestamp_as_time) do |progress|
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

      working_dir = if current_scm.nil? then project_base_dir else current_scm.working_dir end
      with_working_directory(working_dir) do
        # set up some environment variables the build can use

        ENV["DAMAGECONTROL_CHANGES"] = 
          current_build.modification_set.collect{|m| "\"#{m.path}\"" }.join(" ") unless current_build.modification_set.nil?

        ENV["DAMAGECONTROL_BUILD_LABEL"] = current_build.potential_label.to_s

        IO.foreach("|#{current_build.build_command_line} 2>&1") do |line|
          report_progress(line)
        end
        if($? == 0)
          current_build.status = Build::SUCCESSFUL
        else
          current_build.status = Build::FAILED
        end

        # set the label
        if(current_build.successful? && current_build.potential_label)
          current_build.label = current_build.potential_label
        end
      end

    end
 
    def checkout?
      !current_scm.nil?
    end
    
    def project_base_dir
      @project_directories.checkout_dir(current_build.project_name)
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
    
    def building_project?(project_name)
      busy? && current_build.project_name == project_name
    end
    
    def determine_changeset
      return if !checkout?
      # this won't work the first build, so I just skip it
      # the first time a project is built it will have a changeset of every file in the repository
      # this is almost useless information and there's no point in spending lots of time trying to code around it
      return unless File.exists?(current_scm.working_dir)
      
      begin
        last_successful_build = @build_history.last_successful_build(current_build.project_name)
        # we have no record of when the last succesful build was made, don't determine the changeset
        # (might be a new project, see comment above)
        return if last_successful_build.nil?
        time_before = last_successful_build.timestamp_as_time        
        time_after = current_build.timestamp_as_time
        current_build.modification_set = current_scm.changes(time_before, time_after) unless current_scm.nil?

      rescue Exception => e
        logger.error "could not determine changeset: #{format_exception(e)}"
      end
    end
    
    def build_complete
      logger.info("build complete #{current_build.project_name}")
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
    
    def project_checkout_dir
      @project_directories.checkout_dir(current_build.project_name)
    end
    
    def current_scm
      @scm_factory.get_scm(current_build.config, project_checkout_dir)
    end
    
    def process_next_scheduled_build
      next_scheduled_build
      begin
        current_build.start_time = Time.now.to_i

        # set potential label
        last_successful_build = @build_history.last_successful_build(current_build.project_name)
        if(last_successful_build && last_successful_build.label)
          current_build.potential_label = last_successful_build.label + 1
        else
          current_build.potential_label = 1
        end

        @channel.publish_message(BuildStartedEvent.new(current_build))

        determine_changeset
        checkout
        execute
      rescue Exception => e
        message = format_exception(e)
        logger.error("build failed: #{message}")
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
