require 'damagecontrol/Clock'
require 'damagecontrol/Logging'

module DamageControl

  module Threading
    
    include Logging
  
    def new_thread
			Thread.new do
        logger.info "starting #{self}"
        
        yield

        logger.info "stopping #{self}"
			end
    end

    def protect
      begin
        yield
      rescue
        logger.warn "error in #{self}", $!
        @error = $!
      end
    end
		
  end

	module TimerMixin
		attr_accessor :interval
		attr_accessor :next_tick
		attr_reader :error
		attr_reader :stopped
		attr_accessor :clock
    
    include Logging
    include Threading
	
		def clock
			@clock = Clock.new if @clock == nil
			@clock
		end
    
		def start
       new_thread do
        protect { first_tick(clock.current_time) }
        time = clock.current_time
        while (!stopped && next_tick > time)
          sleep( (next_tick - time)/1000 )
          protect { force_tick }
        end
      end
		end
		
		def interval
			@interval || 1000
		end
		
		def stop
			@stopped = true
		end
		
		def schedule_next_tick(interval=interval)
			@next_tick = clock.current_time + interval
		end
    
    def current_time
      clock.current_time
    end

		def first_tick(time)
			schedule_next_tick
		end
		
		def tick(time)
			schedule_next_tick
		end
		
    def force_tick(time=nil)
      if time.nil?
        time = clock.current_time
      else
        @clock = FakeClock.new
        @clock.change_time(time)
      end
      
			tick(time)
		end
	end
	
	class Timer
		include TimerMixin

		def initialize (&proc)
			@proc = proc
		end
		
		def tick(time)
			@proc.call unless @proc == nil
			schedule_next_tick
		end
		
	end
	
end
 