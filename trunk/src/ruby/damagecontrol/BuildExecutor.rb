require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/FileSystem'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor < AsyncComponent
  
    attr_reader :current_build
    attr_reader :builds_dir

    def initialize(channel, builds_dir, scm = DefaultSCMRegistry.new)
      super(channel)
      @channel = channel
      @channel.add_subscriber(self)
      @builds_dir = builds_dir
      @scm = scm
      @filesystem = FileSystem.new
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
      IO.popen(current_build.build_command_line) do |output|
        output.each_line do |line|
          report_progress(line)
          did_read_ant_or_maven_build_failed = true if /BUILD FAILED/ =~ line
          did_read_ruby_tests_failed = true if /Failure!!!/ =~ line
        end
      end
      
      current_build.successful = !(did_read_ant_or_maven_build_failed || did_read_ruby_tests_failed)
    end
 
    def project_base_dir
      "#{@builds_dir}/#{current_build.project_name}"
    end

    def process_message(message)
      if message.is_a? BuildRequestEvent
        @current_build = message.build
        checkout unless current_build.scm_spec.nil?
        execute
        @channel.publish_message(BuildCompleteEvent.new(current_build))
      end
    end

  private

    def report_progress(progress)
      @channel.publish_message(BuildProgressEvent.new(current_build, progress))
    end

  end
  
end
