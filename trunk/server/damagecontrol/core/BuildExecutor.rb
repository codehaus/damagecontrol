require 'pebbles/Space'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor < Pebbles::Space
  
    include FileUtils
    include Logging
    
    attr_reader :current_build
    attr_reader :builds_dir
    
    attr_accessor :last_build_request

    def initialize(channel, build_history_repository, *args)
      super
      @channel = channel
      @build_history_repository = build_history_repository
      
      # TODO remove this, just warning people about refactorings
      raise "NOTE: BuildExecutor has been refactored! It now only takes two arguments, like this: BuildExecutor.new(hub, build_history_repository)" unless args.empty?
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
      # set up some environment variables the build can use
      environment = { "DAMAGECONTROL_BUILD_LABEL" => current_build.potential_label.to_s }
      environment["DAMAGECONTROL_CHANGES"] = 
        current_build.changesets.format(CHANGESET_TEXT_FORMAT, Time.new.utc) unless current_build.changesets.nil?
      report_progress(current_build.build_command_line)
      begin
        @build_process = Pebbles::Process.new
        @build_process.working_dir = working_dir
        @build_process.command_line = current_build.build_command_line
        @build_process.environment = environment
        @build_process.join_stdout_and_stderr = true
        @build_process.execute do |stdin, stdout|
          stdout.each_line {|line| report_progress(line) }
        end
        current_build.status = Build::SUCCESSFUL
      rescue Exception => e
        logger.error("build failed: #{format_exception(e)}")
        report_progress(format_exception(e))
        if was_killed?
          current_build.status = Build::KILLED
        else
          current_build.status = Build::FAILED
        end
      end

      # set the label
      if(current_build.successful? && current_build.potential_label)
        current_build.label = current_build.potential_label
      end

    end
    
    def build_process
      @build_process
    end
    
    def build_process_executing?
      build_process && build_process.executing?
    end
    
    def was_killed?
      @was_killed
    end
    
    def kill_build_process
      build_process.kill
      @was_killed = true
      #doesn't seem to work properly if two different threads are waiting. workaround: sleep a bit to ensure it dies
      #build_process.wait
      sleep 1
    end
 
    def checkout?
      !current_scm.nil?
    end
    
    def project_base_dir
      current_build.scm.working_dir
    end
    
    def scheduled_build
      if busy? then @current_build else nil end
    end
  
    def status_message
      status = ""
      if busy? then
        status = "Building #{scheduled_build.project_name}: #{scheduled_build.status}"
      else
        status = "Idle"
      end
    end
    
    def busy?
      !@current_build.nil?
    end
    
    def building_project?(project_name)
      busy? && current_build.project_name == project_name
    end
    
    def determine_changeset
      current_build.status = Build::DETERMINING_CHANGESETS
      if !current_build.changesets.empty?
        logger.info("does not determine changeset for #{current_build.project_name} because other component (such as SCMPoller) has already determined it")
        return
      end
      if !checkout?
        logger.info("does not determine changeset for #{current_build.project_name} because scm not configured")
        return 
      end
      unless File.exists?(current_scm.working_dir)
        # this won't work the first build, so I just skip it
        # the first time a project is built it will have a changeset of every file in the repository
        # this is almost useless information and there's no point in spending lots of time trying to code around it (not to mention executing it)
        logger.info("does not determine changeset for #{current_build.project_name} because project not yet checked out")
        return
      end
      
      begin
        last_successful_build = @build_history_repository.last_successful_build(current_build.project_name)
        # we have no record of when the last succesful build was made, don't determine the changeset
        # (might be a new project, see comment above)
        return if last_successful_build.nil?
        from_time = last_successful_build.timestamp_as_time        
        to_time = current_build.timestamp_as_time
        logger.info("determining change set for #{current_build.project_name}, from #{from_time} to #{to_time}")
        changesets = current_scm.changesets(from_time, to_time) {|p| report_progress(p)}
        current_build.changesets = changesets if changesets
        logger.info("change set for #{current_build.project_name} is #{current_build.changesets.inspect}")

      rescue Exception => e
        logger.error "could not determine changeset: #{format_exception(e)}"
      end
    end
    
    def build_complete
      logger.info("build complete #{current_build.project_name}")
      current_build.end_time = Time.now.utc
      @channel.publish_message(BuildCompleteEvent.new(current_build))

      # atomically frees the slot, we are now no longer busy
      @current_build = nil
    end
    
    def current_build
      @current_build
    end
    
    def current_scm
      current_build.scm
    end
    
    def build_start
      logger.info("build starting #{current_build.project_name}")
        current_build.start_time = Time.now.utc
        determine_changeset
        @channel.publish_message(BuildStartedEvent.new(current_build))
    end
    
    def on_message(build)
      @current_build = build
      begin
        build_start
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
    
    def report_progress(progress)
      @channel.publish_message(BuildProgressEvent.new(current_build, progress))
    end

  end
  
end
