require 'damagecontrol/Clock'

module DamageControl

  module Threading
    def new_thread
			Thread.new do
        puts "starting #{self}"
        
        yield

        puts "stopping #{self}"
			end
    end

    def protect
      begin
        yield
      rescue
        $stderr.print $!
        $stderr.print "\n"
        $stderr.print $!.backtrace.join("\n")
        $stderr.print "\n"
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
			@next_tick=clock.current_time + interval
		end

		def first_tick(time)
			schedule_next_tick
		end
		
		def tick(time)
			schedule_next_tick
		end
		
		def force_tick
			tick(clock.current_time)
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
