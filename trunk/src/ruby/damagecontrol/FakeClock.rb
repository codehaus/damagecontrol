require 'damagecontrol/Clock'

module DamageControl
	
	class FakeClock < Clock
		def initialize
			@time = 0
			@has_waiters = Latch.new
			@time_changed = Latch.new
		end
		
		def change_time (newtime)
			@time = newtime
			@time_changed.release()
			@time_changed = Latch.new
		end
		
		def wait_for_waiters (timeout=-1)
			@has_waiters.wait()
		end
		
		def current_time
			@time
		end
		
		def wait_until (wait_until_time)
			@has_waiters.release()
			while current_time < wait_until_time
				@time_changed.wait()
			end
		end
	end
	
end