module DamageControl
	class Clock
		def current_time
			Time.now.to_i
		end

		def wait_until (wait_until_time)
			time_to_wait = (wait_until_time - current_time) / 1000
			puts "#{Thread.current} waiting for #{wait_until_time}, time to wait #{time_to_wait}s"
			sleep(time_to_wait / 1000)
		end
	end
end