require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class LogWriter
    
    include Logging
    include FileUtils
  
    def initialize(channel, build_history_repository)
      @open_files = {}
      channel.add_consumer(self)
      @build_history_repository = build_history_repository
    end
    
    def put(event)
      
      return if !event.is_a? BuildEvent

      build = event.build
      
      if event.is_a? BuildProgressEvent
        begin
          stdout_file(build).puts(event.output)
          stdout_file(build).flush
        rescue Exception => e
          logger.error("Couldn't write to file:#{format_exception(e)}")
        end
      end
      
      if event.is_a? BuildErrorEvent
        begin
          stderr_file(build).puts(event.message)
          stderr_file(build).flush
          stdout_file(build).puts(event.message)
          stdout_file(build).flush
        rescue Exception => e
          logger.error("Couldn't write to file:#{format_exception(e)}")
        end
      end
      
      if event.is_a? BuildCompleteEvent
        close_files(build)
      end

    end
    
    def shutdown
      @open_files.each do |name, file|
        file.close unless file.closed?
        @open_files.delete(name)
      end
    end
    
    def stdout_file(build)
      open_file(@build_history_repository.stdout_file(build.project_name, build.dc_creation_time))
    end
    
    def stderr_file(build)
      open_file(@build_history_repository.stderr_file(build.project_name, build.dc_creation_time))
    end
    
  private
    
    def close_files(build)
      begin
        close_file(@build_history_repository.stdout_file(build.project_name, build.dc_creation_time))
        close_file(@build_history_repository.stderr_file(build.project_name, build.dc_creation_time))
      rescue => e
        logger.error("BuildCompleteEvent: Couldn't write to file: #{format_exception(e)}")
      end
    end
    
    def close_file(file_name)
      stdout_file = @open_files[file_name]
      return unless stdout_file
      if stdout_file.closed?
        @open_files.remove(file_name)
        return
      end
      logger.info("closing log file #{file_name}")
      stdout_file.flush
      stdout_file.close
    end
    
    def open_file(file_name)
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
