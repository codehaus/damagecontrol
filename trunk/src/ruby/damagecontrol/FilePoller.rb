require 'damagecontrol/Timer'

module DamageControl

  class FilePoller

    include TimerMixin

    def initialize(dir_to_poll, file_handler=self)
      @dir_to_poll = File.expand_path(dir_to_poll)
      @parent_dir = File.dirname(@dir_to_poll)
      @file_handler = file_handler

      discover_files
    end
    
    def tick(time)
      foreach do |filename|
      	begin
          @file_handler.new_file(filename) if is_new_file(filename)
	rescue
	  puts "error processing #{filename}, ignoring"
	end
      end
      discover_files
      schedule_next_tick
    end
    
  private
  
    def is_new_file(filename)
      discovered = @discovered_files.index(filename)
      is_dir = @dir_to_poll == filename
      is_parent = @parent_dir == filename

      !discovered && !is_dir && !is_parent
    end

    def foreach
      Dir.foreach(@dir_to_poll) do |filename|
        yield File.expand_path("#{@dir_to_poll}/#{filename}")
      end
    end
        
    def discover_files
      @discovered_files = []
      foreach do |filename|
        @discovered_files << filename
      end
    end

  end

end
