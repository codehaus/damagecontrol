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
        puts(message.output)
        begin
          log_file(message.build).puts(message.output)
          log_file(message.build).flush
        rescue => e
          puts "BuildProgressEvent: Couldn't write to file #{log_file(message.build).path}:#{e.message}"
        end
      end

      if message.is_a? BuildCompleteEvent
        puts("BuildCompleteEvent")
        begin
          log_file(message.build).flush
          log_file(message.build).close
        rescue => e
          puts "BuildCompleteEvent: Couldn't write to file #{log_file(message.build).path}:#{e.message}"
        end
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
