require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class LogWriter
    
    include Logging
    include FileUtils
  
    def initialize(channel)
      @log_files = {}
      channel.add_subscriber(self)
    end
    
    def put(message)
      
      return if !message.is_a? BuildEvent

      build = message.build
      
      if message.is_a? BuildProgressEvent
        begin
          log_file(build).puts(message.output)
          log_file(build).flush
        rescue Exception => e
          logger.error("Couldn't write to file:#{format_exception(e)}")
        end
      end
      
      if message.is_a? BuildCompleteEvent
        begin
          logger.debug("closing file #{log_file(build)}") if logger.debug?
          log_file(build).flush
          log_file(build).close
        rescue => e
          logger.error("BuildCompleteEvent: Couldn't write to file:#{format_exception(e)}")
        end
      end

    end
    
    def log_file(build)
      file_name = build.log_file
      file = @log_files[file_name]
      if(!file)
        logger.debug("opening file #{file_name}") if logger.debug?
        mkdir_p(File.dirname(file_name))
        file = File.open(file_name, "w")
        @log_files[file_name] = file
      end
      file
    end
  end

end
