module DamageControl
	class Clock
		def current_time
			Time.now.to_i
		end

		def wait_until (wait_until_time)
			sleep(wait_until_time - current_time)
		end
	end
end