require 'ftools'
require 'damagecontrol/BuildEvents'

module DamageControl

  class LogWriter
  
    def initialize(channel, logs_base_dir)
      @log_files = {}
      @logs_base_dir = logs_base_dir

      channel.add_subscriber(self)
    end
    
    def receive_message(message)
      
      if message.is_a? BuildEvent
        build = message.build

        if message.is_a? BuildProgressEvent
          puts("[#{build.project_name}]:" + message.output)
          begin
            log_file(build).puts(message.output)
            log_file(build).flush
        rescue => e
          puts "BuildProgressEvent: Couldn't write to file #{log_file_name(build)}:#{e.message}"
        end
      end

      if message.is_a? BuildCompleteEvent
        puts("[#{build.project_name}]: BUILD COMPLETE")
        begin
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
        File.makedirs(File.dirname(file_name))
        file = File.open(file_name, "w")
        @log_files[file_name] = file
      end
      file
    end
  end

end
