require 'damagecontrol/Hub'
require 'damagecontrol/Clock'

module DamageControl

	class FrequencyTriggerEvent
	end
	
	class FrequencyTrigger
		attr_accessor :message
		attr_accessor :interval
		attr_reader :error
	
		def initialize (hub, clock)
			@hub = hub
			@clock = clock
			message = FrequencyTriggerEvent.new
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
			@clock.wait_until(@clock.current_time() + interval)
			@hub.publish_message(message)
		end
	end
	
end
