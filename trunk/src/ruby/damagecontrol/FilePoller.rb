require 'damagecontrol/Timer'

module DamageControl

  class FilePoller

    include TimerMixin

    def initialize(dir_to_poll, file_handler)
      @dir_to_poll = File.expand_path(dir_to_poll)
      @parent_dir = File.dirname(@dir_to_poll)
      @file_handler = file_handler

      discover_files
    end
    
    def tick(time)
      foreach do |filename|
        @file_handler.new_file(filename) if is_new_file(filename)
      end
      discover_files
      schedule_next_tick
    end
    
  private
  
    def is_new_file(filename)
      discovered = @discovered_files.index(filename)
      is_dir = @dir_to_poll == filename
      is_par = @parent_dir == filename

      !discovered && !is_dir && !is_par
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