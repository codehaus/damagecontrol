require 'test/unit'
require 'damagecontrol/FrequencyTrigger'

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
	
	class FrequencyTriggerTest < Test::Unit::TestCase
		def setup
			@clock = FakeClock.new
			@hub = Hub.new
			@hub.clock = @clock
			@trigger = FrequencyTrigger.new(@hub, @clock)
		end
		
		def test_trigger
			@trigger.message = "message"
			@trigger.interval = 10
			@clock.change_time(0)
			
			@trigger.start
			@clock.wait_for_waiters
			
			@clock.change_time(5)
			assert_nil(@hub.last_message)

			@clock.change_time(11)
			dump_threads
			@hub.wait_for_next_publication if @hub.last_message == nil
			assert_equal(@trigger.message, @hub.last_message)
			
			assert_nil(@trigger.error)
		end
		
		def dump_threads
			ObjectSpace.each_object(Thread) { |t|
				puts "thread #{t}, status=#{t.status}, stopped=#{t.stop?}"
			}
		end
	end
		
end
