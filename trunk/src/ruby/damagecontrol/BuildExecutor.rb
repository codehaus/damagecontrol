require 'damagecontrol/BuildEvents'
require 'damagecontrol/scm/DefaultSCMRegistry'
require 'damagecontrol/FileSystem'

module DamageControl
  
  # This class tells the build to execute and reports
  # progress as events back to the channel
  #
  class BuildExecutor
  
    attr_reader :current_build
    attr_reader :builds_dir

    def initialize(channel, builds_dir, scm = DefaultSCMRegistry.new)
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
      @filesystem.chdir(project_base_dir)
      current_build.successful = IO.popen(current_build.build_command_line) do |output|
        output.each_line do |line|
          report_progress(line)
        end
      end
    end
 
    def project_base_dir
      "#{@builds_dir}/#{current_build.project_name}"
    end

    def report_progress(progress)
      @channel.publish_message(BuildProgressEvent.new(current_build, progress))
    end

    def receive_message(message)
      if message.is_a? BuildRequestEvent
        @current_build = message.build
        checkout unless current_build.scm_spec.nil?
        execute
        @channel.publish_message(BuildCompleteEvent.new(current_build))
      end
    end
  end
  
end
