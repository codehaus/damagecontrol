require 'ftools'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'

module DamageControl

  class LogWriter
    
    include Logging
  
    def initialize(channel, logs_base_dir)
      @log_files = {}
      @logs_base_dir = logs_base_dir

      channel.add_subscriber(self)
    end
    
    def receive_message(message)
      
      return if !message.is_a? BuildEvent

      build = message.build
      
      if message.is_a? BuildProgressEvent
        begin
          log_file(build).puts(message.output)
          log_file(build).flush
        rescue => e
          puts "BuildProgressEvent: Couldn't write to file #{log_file_name(build)}:#{e.message}"
        end
      end
      
      if message.is_a? BuildCompleteEvent
        begin
          logger.debug("closing file #{log_file_name(build)}") if logger.debug?
          log_file(build).flush
          log_file(build).close
        rescue => e
          puts "BuildCompleteEvent: Couldn't write to file #{log_file_name(build)}:#{e.message}"
        end
      end

    end
    
    def log_file_name(build)
      "#{@logs_base_dir}/#{build.project_name}/#{build.timestamp}.log"
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
