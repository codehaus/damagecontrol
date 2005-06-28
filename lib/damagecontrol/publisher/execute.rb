require 'fileutils'
require 'rscm/path_converter' #TODO: move safer_popen to popen_ext.rb
require 'damagecontrol/publisher/base'

module DamageControl

  class Build
    def execute_publisher_stdout
      File.expand_path("#{execute_publisher_dir}/stdout.log")
    end

    def execute_publisher_stderr
      File.expand_path("#{execute_publisher_dir}/stderr.log")
    end
    
    def execute_publisher_dir
      File.expand_path("#{dir}/execute_publisher")
    end
  end

  module Publisher
    class Execute < Base
      #register self
    
      ann :description => "Command line"
      ann :tip => "Stdout and stderr for the command will be made available on the build page. Don't redirect streams."
      attr_accessor :command_line

      ann :description => "Directory"
      ann :tip => "Relative directory (under checkout directory) where the command will be executed."
      attr_accessor :command_line

      def initialize
        @command_line = "echo \"The build label is $DAMAGECONTROL_BUILD_LABEL\""
      end

      def name
        "Execute"
      end    

      def publish(build)
        FileUtils.mkdir_p(build.execute_publisher_dir)
        safer_popen("{@command_line} > \"#{build.execute_publisher_stdout}\" 2> \"#{build.execute_publisher_stderr}\"") do |io|
          io.read
        end
      end
    end
  end
end