require 'pebbles/Space'
require 'pebbles/Process'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
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
    attr_reader :name
    
    attr_accessor :last_build_request

    def initialize(name, channel, project_directories, build_history_repository)
      super
      @channel = channel
      @project_directories = project_directories
      @build_history_repository = build_history_repository
      @name = name
    end
    
    def checkout?
      !current_scm.nil?
    end
    
    def checkout
      return if !checkout?
      
      current_build.status = Build::CHECKING_OUT
      current_scm.checkout(checkout_dir, current_build.scm_commit_time) do |progress|
        report_progress(progress)
      end
    end
    
    def checkout_dir
      @project_directories.checkout_dir(current_build.project_name)
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

      # set up some environment variables the build can use
      environment = { "DAMAGECONTROL_BUILD_LABEL" => current_build.potential_label.to_s }
      unless current_build.changesets.nil?
        environment["DAMAGECONTROL_CHANGES"] = 
          current_build.changesets.format(CHANGESET_TEXT_FORMAT, Time.new.utc)
      end
      report_progress(current_build.build_command_line)
      begin
        @build_process = Pebbles::Process.new
        @build_process.working_dir = checkout_dir
        @build_process.environment = environment
        @build_process.execute(current_build.build_command_line) do |stdin, stdout, stderr|
          threads = []
          threads << Thread.new { stdout.each_line {|line| report_progress(line) } }
          threads << Thread.new { stderr.each_line {|line| report_error(line) } }
          threads.each{|t| t.join}
        end
        current_build.status = Build::SUCCESSFUL
      rescue Exception => e
        logger.error("build failed: #{format_exception(e)}")
        report_error(format_exception(e))
        if was_killed?
          current_build.status = Build::KILLED
        else
          current_build.status = Build::FAILED
        end
      end

      # set the label
      if(current_build.successful?)
        current_scm_label = current_scm.label(checkout_dir)
        if(current_scm_label)
          current_build.label = current_scm_label
        else
          current_build.label = current_build.potential_label
        end
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
    
    def scheduled_build
      if busy? then @current_build else nil end
    end
  
    def status_message
      status = ""
      if busy? then
        status = "Building <a href=\"project/#{scheduled_build.project_name}\">#{scheduled_build.project_name}</a>: #{scheduled_build.status}"
      else
        status = "Idle"
      end
    end
    
    def executor_selector(build)
      Regexp.new(build.config['executor_selector'] || '.*')
    end
    
    # overload to specify more clever scheduling mechanism, like some executors are reserved for some builds etc
    def can_execute?(build)
      !busy? && executor_selector(build) =~ (name)
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
        logger.info("not determining changeset for #{current_build.project_name} because other component (such as SCMPoller) has already determined it")
        return
      end
      if !checkout?
        logger.info("not determining changeset for #{current_build.project_name} because scm not configured")
        return 
      end
      unless File.exists?(checkout_dir)
        # this won't work the first build, so I just skip it
        # the first time a project is built it will have a changeset of every file in the repository
        # this is almost useless information and there's no point in spending lots of time trying to code around it (not to mention executing it)
        logger.info("not determining changeset for #{current_build.project_name} because project not yet checked out - #{checkout_dir} does not exist")
        return
      end
      
      begin
        last_successful_build = @build_history_repository.last_successful_build(current_build.project_name)
        from_time = last_successful_build ? last_successful_build.scm_commit_time : nil
        from_time = from_time ? from_time + 1 : nil
        logger.info("Determining changesets for #{current_build.project_name} from #{from_time}")
        changesets = current_scm.changesets(checkout_dir, from_time, nil, nil) {|p| report_progress(p)}
        # Only store changesets if the previous commit time was known
        current_build.changesets = changesets if changesets && from_time
        
        # Set last commit time
        changesets = changesets.sort do |a,b|
          a.time <=> b.time
        end
        current_build.scm_commit_time = changesets[-1] ? changesets[-1].time : nil

      rescue Exception => e
        logger.error "could not determine changeset: #{format_exception(e)}"
      end
    end
    
    def build_complete
      logger.info("build complete #{current_build.project_name}")
      current_build.duration = (Time.now.utc - current_build.dc_start_time).to_i
      @channel.put(BuildCompleteEvent.new(current_build))

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
      @was_killed = false
      logger.info("build starting #{current_build.project_name}")
      current_build.dc_start_time = Time.now.utc
      determine_changeset
      @channel.put(BuildStartedEvent.new(current_build))
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
        report_error("Build failed due to: #{message}")
      ensure
        build_complete
      end
    end
    
    def report_progress(progress)
      @channel.put(BuildProgressEvent.new(current_build, progress))
    end

    def report_error(message)
      @channel.put(BuildErrorEvent.new(current_build, message))
    end

  end
  
end
