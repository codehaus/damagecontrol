require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/FileSystem'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor
    
    include TimerMixin
  
    attr_reader :current_build
    attr_reader :builds_dir
    attr_writer :checkout
    attr_accessor :quiet_period
    
    attr_accessor :last_build_request

    def initialize(channel, builds_dir, scm = DefaultSCMRegistry.new, quiet_period=default_quiet_period)
      @channel = channel
      channel.add_subscriber(self)
      @builds_dir = builds_dir
      @scm = scm
      @filesystem = FileSystem.new
      @checkout = true
      @quiet_period = quiet_period
    end
    
    def default_quiet_period
      0
    end
    
    def checkout
      @scm.checkout(current_build.scm_spec, project_base_dir) do |progress| 
        report_progress(progress)
      end
    end

    def execute
      @filesystem.makedirs(project_base_dir)
      @filesystem.chdir(project_base_dir)
 
      # temp hack that only works for Ant/Maven and Ruby tests. We need to get the return code!!!
      did_read_ant_or_maven_build_failed = false
      did_read_ruby_tests_failed = false
      # some of the error messages are on stderr, which isn't available to popen
      IO.foreach("|#{current_build.build_command_line} 2>&1") do |line|
        report_progress(line)
        did_read_ant_or_maven_build_failed = true if /FAILED/ =~ line
        did_read_ruby_tests_failed = true if /Failure!!!/ =~ line || /Error!!!/ =~ line
      end
      
      current_build.successful = !(did_read_ant_or_maven_build_failed || did_read_ruby_tests_failed)
    end
 
    def project_base_dir
      "#{@builds_dir}/#{current_build.project_name}"
    end
    
    def checkout?
      @checkout && !current_build.scm_spec.nil?
    end
    
    def quiet_period_elapsed
      !last_build_request.nil? && (clock.current_time - quiet_period) >= last_build_request
    end
    
    def tick(time)
        if quiet_period_elapsed
          checkout if checkout?
          execute
          @channel.publish_message(BuildCompleteEvent.new(current_build))
        end
    end

    def receive_message(message)
      if message.is_a? BuildRequestEvent
        @current_build = message.build
        @last_build_request = Build.timestamp_to_i(message.build.timestamp)
      end
    end

  private

    def report_progress(progress)
      @channel.publish_message(BuildProgressEvent.new(current_build, progress))
    end

  end
  
end
