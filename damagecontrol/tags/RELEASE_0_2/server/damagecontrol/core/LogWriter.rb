require 'ftools'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'

module DamageControl

  class LogWriter
    
    include Logging
  
    def initialize(channel, project_directories)
      @log_files = {}
      @project_directories = project_directories

      channel.add_subscriber(self)
    end
    
    def receive_message(message)
      
      return if !message.is_a? BuildEvent

      build = message.build
      
      if message.is_a? BuildProgressEvent
        begin
          log_file(build).puts(message.output)
          log_file(build).flush
        rescue Exception => e
          logger.error("Couldn't write to file #{log_file_name(build)}:#{format_exception(e)}")
        end
      end
      
      if message.is_a? BuildCompleteEvent
        begin
          logger.debug("closing file #{log_file_name(build)}") if logger.debug?
          log_file(build).flush
          log_file(build).close
        rescue => e
          logger.error("BuildCompleteEvent: Couldn't write to file #{log_file_name(build)}:#{format_exception(e)}")
        end
      end

    end
    
    def log_file_name(build)
      log_dir = @project_directories.log_dir(build.project_name)
      "#{log_dir}/#{build.timestamp}.log"
    end

    def log_file(build)
      file_name = log_file_name(build)
      file = @log_files[file_name]
      if(!file)
        logger.debug("opening file #{file_name}") if logger.debug?
        File.makedirs(File.dirname(file_name))
        file = File.open(file_name, "w")
        @log_files[file_name] = file
      end
      file
    end
  end

end
