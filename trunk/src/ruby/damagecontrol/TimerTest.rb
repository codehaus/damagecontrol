require 'test/unit'
require 'damagecontrol/Timer'
require 'damagecontrol/FakeClock'

module DamageControl

	class TimerTest < Test::Unit::TestCase
		def setup
			@clock = FakeClock.new
			@hub = Hub.new
			@hub.clock = @clock
			@timer = Timer.new {
				@hub.publish_message("message")
			}
			@timer.clock = @clock
		end
		
		def test_trigger
			@timer.interval = 10
			@clock.change_time(0)
			
			@timer.start
			@clock.wait_for_waiters
			
			@clock.change_time(5)
			assert_nil(@hub.last_message)

			@clock.change_time(11)
			@hub.wait_for_next_publication if @hub.last_message == nil
			assert_equal("message", @hub.last_message)
			
			assert_nil(@timer.error)
		end
		
		def dump_threads
			ObjectSpace.each_object(Thread) { |t|
				puts "thread #{t}, status=#{t.status}, stopped=#{t.stop?}"
			}
		end
	end
		
end
