require 'ftools'
require 'damagecontrol/BuildEvents'

module DamageControl

  class LogWriter
  
    def initialize(channel, logs_base_dir)
      @log_files = {}      
      channel.add_subscriber(self)
      @logs_base_dir = logs_base_dir
    end
    
    def receive_message(message)
      
      if message.is_a? BuildProgressEvent
        log_file(message.build).puts(message.output)
      end

      if message.is_a? BuildCompleteEvent
        log_file(message.build).flush
        log_file(message.build).close
      end
    end

    def log_file(build)
      file_name = "#{@logs_base_dir}/#{build.project_name}/#{build.timestamp}.log"
      file = @log_files[file_name]
      if(!file)
        dir = File.dirname(file_name)
        File.makedirs(dir)
        file = File.open(file_name, "w")
        @log_files[file_name] = file
      end
      file
    end
  end

end
