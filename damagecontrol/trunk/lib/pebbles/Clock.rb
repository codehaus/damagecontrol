module Pebbles
  class Clock
    attr_reader :exception
  
    def initialize(seconds, callback=self, &proc)
      @seconds = seconds
      @callback = callback
      @proc = proc
      @run = true
    end
    
    def time_to_next_tick
      (@started - Time.now) + @seconds
    end

    def start
      raise "interval can't be null" unless @seconds
      shutdown
      @run = true
      return increase if @seconds == 0
      @sleeper = Thread.new do
        while(@run)
          @started = Time.now
          sleep @seconds
          begin
            increase
          rescue Exception => e
            @callback.exception(e)
          end
        end
      end
    end
    
    def shutdown
      @run = false
      @sleeper.kill if @sleeper and @sleeper.alive?
    end
    
    def tick(time)
      @proc.call(time) if @proc
    end
    
    def exception(e)
      puts e
      puts e.backtrace.join("\n")
    end

  protected

    def increase
      @callback.tick(Time.new.utc)
    end

  end
  
  class Countdown < Clock
    def increase
      super
      shutdown
    end
    
    alias :time_left :time_to_next_tick
  end
end
