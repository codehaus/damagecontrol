module DamageControl
	class Clock
	
		attr_reader :receivers
		
		def initialize
			@receivers = []
		end
	
		def current_time
			Time.now.to_i
		end

		def register(receiver)
			receivers<<receiver
		end

		def unregister(receiver)
			receivers.delete(receiver)
		end

		def wait_until (wait_until_time)
			time_to_wait = (wait_until_time - current_time) / 1000
			puts "#{Thread.current} waiting for #{wait_until_time}, time to wait #{time_to_wait}s"
			sleep(time_to_wait / 1000)
		end

		def do_tick
			do_tick(current_time())
		end
		
		def do_tick(time)
			receivers.each {|receiver|
				receiver.tick(time)
			}
		end
		
	end
	
	# Chris: I think this is a better usage pattern?
	class Ticker < Clock
		
	end
	
end