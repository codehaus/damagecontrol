require 'damagecontrol/Clock'

module DamageControl

	class Timer
		attr_accessor :interval
		attr_reader :error
		attr_accessor :clock
	
		def initialize (&proc)
			@clock = Clock.new
			@proc = proc
		end
		
		def start
			Thread.new {
				begin
					puts "starting #{self}"
					run
				rescue
					$stderr.print $!
					$stderr.print "\n"
					$stderr.print $!.backtrace.join("\n")
					$stderr.print "\n"
					@error = $!
				ensure
					puts "stopping #{self}"
				end
			}
		end
		
		def run
			clock.wait_until(clock.current_time() + interval)
			@proc.call
		end
	end
	
end
