require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class LogWriter
    
    include Logging
    include FileUtils
  
    def initialize(channel)
      @open_files = {}
      channel.add_subscriber(self)
    end
    
    def put(event)
      
      return if !event.is_a? BuildEvent

      build = event.build
      
      if event.is_a? BuildProgressEvent
        begin
          log_file(build).puts(event.output)
          log_file(build).flush
        rescue Exception => e
          logger.error("Couldn't write to file:#{format_exception(e)}")
        end
      end
      
      if event.is_a? BuildErrorEvent
        begin
          error_log_file(build).puts(event.message)
          error_log_file(build).flush
          log_file(build).puts(event.message)
          log_file(build).flush
        rescue Exception => e
          logger.error("Couldn't write to file:#{format_exception(e)}")
        end
      end
      
      if event.is_a? BuildCompleteEvent
        close_log_files(build)
      end

    end
    
    def shutdown
      @open_files.each do |name, file|
        file.close unless file.closed?
        @open_files.delete(name)
      end
    end
    
    def close_log_files(build)
        begin
          close_log_file(build.log_file)
          close_log_file(build.error_log_file)
        rescue => e
          logger.error("BuildCompleteEvent: Couldn't write to file: #{format_exception(e)}")
        end
    end
    
    def log_file(build)
      open_log_file(build.log_file)
    end
    
    def error_log_file(build)
      open_log_file(build.error_log_file)
    end
    
    private
    
    def close_log_file(file_name)
      log_file = @open_files[file_name]
      return unless log_file
      if log_file.closed?
        @open_files.remove(file_name)
        return
      end
      logger.info("closing log file #{file_name}")
      log_file.flush
      log_file.close
    end
    
    def open_log_file(file_name)
      file = @open_files[file_name]
      if(!file)
        logger.info("opening log file #{file_name}")
        mkdir_p(File.dirname(file_name))
        file = File.open(file_name, "w")
        @open_files[file_name] = file
      end
      file
    end
  end

end
