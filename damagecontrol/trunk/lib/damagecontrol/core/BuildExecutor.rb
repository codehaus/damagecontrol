require 'pebbles/Space'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/Logging'

module DamageControl
  
  class Kill
    def initialize(process)
      @process = process
    end
    
    def kill
      @process.kill unless @process.nil?
    end
  end
  
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

    def initialize(name, channel, project_config_repository, build_history_repository, project_directories)
      super
      @channel = channel
      @project_config_repository = project_config_repository
      @build_history_repository = build_history_repository
      @project_directories = project_directories
      @name = name
    end
    
    def checkout?
      !current_scm.nil?
    end
    
    def checkout
      return if !checkout?
      
      current_build.status = Build::CHECKING_OUT
      @channel.put(BuildStateChangedEvent.new(current_build))
      # we're not specifying scm_to_time since we don't know that time. we cannot safely
      # assume that it is the same time as *now* on the machine where this process (DC)
      # is running. therefore, specify nil and get the latest. In worst case we'll get
      # some more changes than wanted in case someone committed files after the build request,
      # but chances of this happening are rather slim, and if it happens it isn't a big problem.
      current_scm.checkout(checkout_dir, nil) do |line|
        stdout(line)
      end

      # set the label
      scm_label = current_scm.label(checkout_dir)
      custom_label = @project_config_repository.peek_next_build_label(current_build.project_name)
      if(scm_label && custom_label < 0)
        previous_label = @build_history_repository.prev(current_build, false).label

        # We need to append a sub label to distinguish the builds
        if(previous_label && previous_label =~ /([0-9]+)[\.]?([0-9]*)/ && $1.to_i == scm_label.to_i)
          sub_label = $2 ? $2.to_i + 1 : 1
          scm_label = "#{$1}.#{sub_label}"
        end

        current_build.label = scm_label
      else
        current_build.label = custom_label
        @project_config_repository.inc_build_label(current_build.project_name)
      end
    end
    
    def checkout_dir
      @project_config_repository.checkout_dir(current_build.project_name)
    end
    
    def execute
      current_build.status = Build::BUILDING
      @channel.put(BuildStateChangedEvent.new(current_build))

      # set up some environment variables the build can use
      environment = { 
        "DAMAGECONTROL_BUILD_LABEL" => current_build.label.to_s, # DC style
        "PKG_BUILD" => current_build.label.to_s # Seems to be Rake (and other build systems?) common convention..
      }
      unless current_build.changesets.nil?
#        environment["DAMAGECONTROL_CHANGES"] = 
#          current_build.changesets.format(CHANGESET_TEXT_FORMAT, Time.new.utc)
      end
      stdout(current_build.build_command_line)
      cmd_with_io(checkout_dir, current_build.build_command_line, @stderr_file, environment, 60*3600) do |stdout, process|
        begin
          @process = process
          write_to_file(stdout, @stdout_file)
          current_build.status = process && process.killed? ? Build::KILLED : Build::SUCCESSFUL
        ensure
          @channel.put(BuildStateChangedEvent.new(current_build))
        end
      end
    end

    def build_process_executing?
      @process && @process.running?
    end
    
    def kill_build_process
      # Has to be killed by same thread as the one starting it.
      @channel.put(Kill.new(@process))
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
      @channel.put(BuildStateChangedEvent.new(current_build))
      if !checkout?
        logger.info("Not determining changeset for #{current_build.project_name} because scm not configured")
        return 
      end
      unless File.exists?(checkout_dir)
        # this won't work the first build, so I just skip it
        # the first time a project is built it will have a changeset of every file in the repository
        # this is almost useless information and there's no point in spending lots of time trying to code around it (not to mention executing it)
        logger.info("Not determining changeset for #{current_build.project_name} because project not yet checked out - #{checkout_dir} does not exist")
        return
      end
      
      begin
        # TODO: refactor. same code as in SCMPoller
        last_completed_build = @build_history_repository.last_completed_build(current_build.project_name)
        from_time = last_completed_build ? last_completed_build.scm_commit_time : nil
        from_time = from_time ? from_time + 1 : nil

        changesets = current_build.changesets
        if !current_build.changesets.empty?
          logger.info("Not determining changeset for #{current_build.project_name} because other component (such as SCMPoller) has already determined it")
        else
          logger.info("Determining changesets for #{current_build.project_name} from #{from_time}")
          changesets = current_scm.changesets(checkout_dir, from_time, nil, nil) {|line| stdout(line)}
        end

        # Only store changesets if the previous commit time was known
        current_build.changesets = changesets if changesets && from_time
        
        # Set last commit time
        changesets = changesets.sort do |a,b|
          a.time <=> b.time
        end
        current_build.scm_commit_time = changesets[-1] ? changesets[-1].time : @build_history_repository.last_commit_time(current_build.project_name)
        logger.info("Done determining changesets for #{current_build.project_name}. Last commit time: #{current_build.scm_commit_time}")
        @channel.put(BuildStateChangedEvent.new(current_build))
      rescue Exception => e
        logger.error "Could not determine changeset: #{format_exception(e)}"
      end
    end
    
    def build_complete
    end
    
    def current_build
      @current_build
    end
    
    def current_scm
      current_build.scm
    end
    
    def build_start
      logger.info("build starting #{current_build.project_name}")
      current_build.dc_start_time = Time.now.utc
      determine_changeset
      @channel.put(BuildStartedEvent.new(current_build))
    end
    
    def on_message(message)
      # Must kill in the same thread
      if(message.is_a?(Kill))
        message.kill
        return
      end

      @current_build = message
      @stdout_file = @project_directories.stdout_file(current_build.project_name, current_build.dc_creation_time)
      @stderr_file = @project_directories.stderr_file(current_build.project_name, current_build.dc_creation_time)

      begin
        build_start
        checkout
        execute
      rescue Exception => e
        message = format_exception(e)
        logger.error("build failed: #{message}")
        current_build.error_message = message
        current_build.status = Build::FAILED
        @channel.put(BuildStateChangedEvent.new(current_build))
        stderr("Build failed due to: #{message}")
      ensure
        logger.info("Build complete #{current_build.project_name}")
        current_build.duration = (Time.now.utc - current_build.dc_start_time).to_i
        @channel.put(BuildCompleteEvent.new(current_build))

        # atomically frees the slot, we are now no longer busy
        @current_build = nil
      end
    end
    
    def stdout(s)
      @channel.put(StandardOutEvent.new(current_build, s))
    end

    def stderr(s)
      @channel.put(StandardErrEvent.new(current_build, s))
    end

  end
  
end
