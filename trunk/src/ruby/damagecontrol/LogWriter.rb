require 'ftools'
require 'damagecontrol/Hub'
require 'damagecontrol/BuildEvents'

module DamageControl

  class LogWriter
  
    def initialize (hub)
      @log_files = Hash.new      
      hub.add_subscriber(self)      
    end
    
    def receive_message (message)
      
      if message.is_a? BuildProgressEvent
        log_file(message).puts(message.output)
      end

      if message.is_a? BuildCompleteEvent
        log_file(message).close
      end
    end

    def log_file(message)
      file = @log_files[message.build.log_file]
      if(!file)
        dir = File.dirname(message.build.log_file)
        File.makedirs(dir)
        file = File.open(message.build.log_file, "w")
        @log_files[message.build.log_file] = file
      end
      file
    end
  end

end