require 'ftools'
require 'damagecontrol/BuildEvents'

module DamageControl

  class LogWriter
  
    def initialize(channel)
      @log_files = Hash.new      
      channel.add_subscriber(self)      
    end
    
    def receive_message(message)
      
      if message.is_a? BuildProgressEvent
        log_file(message).puts(message.output)
      end

      if message.is_a? BuildCompleteEvent
        log_file(message).flush
        log_file(message).close
      end
    end

    def log_file(message)
      file = @log_files[message.build.absolute_log_file_path]
      if(!file)
        dir = File.dirname(message.build.absolute_log_file_path)
        File.makedirs(dir)
        file = File.open(message.build.absolute_log_file_path, "w")
        @log_files[message.build.absolute_log_file_path] = file
      end
      file
    end
  end

end
