require 'damagecontrol/FileSystem'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Clock'

module DamageControl

  class LogWriter
    attr_reader :current_log
    attr_accessor :clock
  
    def initialize (hub, file_system=FileSystem.new)
      @clock = Clock.new
      @file_system = file_system
      hub.add_subscriber(self)
    end
    
    def receive_message (message)

      if message.is_a? BuildRequestEvent
        log = "#{clock.current_time}.log"
        @current_log = @file_system.newFile(message.build.log_file(log), "rw")
      end
      
      if message.is_a? BuildProgressEvent
        current_log.puts(message.output)
      end

      if message.is_a? BuildCompleteEvent
        current_log.close
      end
      
    end
  end

end