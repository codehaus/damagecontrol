require 'pebbles/Space'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  # Whenever a project is checked out/updated, the timestamp of the most recent commit
  # (in UTC, according to the SCM machine's clock) is stored in the project config.
  #
  class BuildExecutor < Pebbles::Space
  
    include FileUtils
    include Logging
    
    attr_reader :current_build
    attr_reader :name
    
    attr_accessor :last_build_request

    def initialize(name, channel, project_directories)
      super
      @name = name
      @channel = channel
      @project_directories = project_directories
    end
    
    def on_message(build)
      if(build.is_a?(Build))
        @current_build = build
        begin
          execute(build)
        rescue Exception => e
          message = format_exception(e)
          logger.error("build failed: #{message}")
          current_build.error_message = message
          current_build.status = Build::FAILED
          report_error("Build failed due to: #{message}")
        ensure
          build_complete(build)
        end
      end
    end
    
    def kill_build_process
      @build_process.kill
      @was_killed = true
      #doesn't seem to work properly if two different threads are waiting. workaround: sleep a bit to ensure it dies
      #build_process.wait
      sleep 1
    end
 
    # overload to specify more clever scheduling mechanism, like some executors are reserved for some builds etc
    def can_execute?(build)
      !busy? && executor_selector(build) =~ (name)
    end

    # checking out or executing
    def busy?
      !@current_build.nil?
    end
    
    def build_process_executing?
      @build_process && @build_process.executing?
    end
    
    def building_project?(project_name)
      busy? && current_build.project_name == project_name
    end
        
    def scheduled_build
      if busy? then @current_build else nil end
    end
  
    def status_message
      status = ""
      if busy? then
        status = "Building <a href=\"project?project_name=#{scheduled_build.project_name}\">#{scheduled_build.project_name}</a>: #{scheduled_build.status}"
      else
        status = "Idle"
      end
    end
    
  private
    
    def execute(build)
      build.start_time = Time.now.utc
      build.status = Build::BUILDING
      logger.info("Starting build of #{build.project_name}")
      @channel.put(BuildStartedEvent.new(build))

      label = label(build)
      # set up some environment variables the build can use
      environment = { "DAMAGECONTROL_BUILD_LABEL" => label.to_s }
      unless build.changesets.nil?
        environment["DAMAGECONTROL_CHANGES"] = build.changesets.format(CHANGESET_TEXT_FORMAT, build.start_time)
      end
      report_progress(build.build_command_line)
      begin
        @build_process = Pebbles::Process.new
        @build_process.working_dir = checkout_dir
        @build_process.environment = environment
        @was_killed = false
        @build_process.execute(build.build_command_line) do |stdin, stdout, stderr|
          threads = []
          threads << Thread.new { stdout.each_line {|line| report_progress(line) } }
          threads << Thread.new { stderr.each_line {|line| report_error(line) } }
          threads.each{|t| t.join}
        end
        build.status = Build::SUCCESSFUL
      rescue Exception => e
        logger.error("Build failed: #{format_exception(e)}")
        report_error(format_exception(e))
        if(@was_killed)
          build.status = Build::KILLED
        else
          build.status = Build::FAILED
        end
      ensure
        @build_process = nil
      end

      # set the label
      if(build.successful?)
        build.label = label
      end

    end
    
    def label(build)
      scm_label = build.scm.label(checkout_dir)
      scm_label ? scm_label : build.potential_label
    end

    def checkout_dir
      @project_directories.checkout_dir(current_build.project_name)
    end
    
    def executor_selector(build)
      Regexp.new(build.config['executor_selector'] || '.*')
    end
    
    def build_complete(build)
      logger.info("Build complete #{build.project_name}: #{build.status}")
      build.end_time = Time.now.utc
      @channel.put(BuildCompleteEvent.new(build))

      # atomically frees the slot, we are now no longer busy
      @current_build = nil
    end
    
    def current_build
      @current_build
    end
    
    def current_scm
      current_build.scm
    end
    
    def report_progress(progress)
      @channel.put(BuildProgressEvent.new(current_build, progress))
    end

    def report_error(message)
      @channel.put(BuildErrorEvent.new(current_build, message))
    end

  end
  
end
