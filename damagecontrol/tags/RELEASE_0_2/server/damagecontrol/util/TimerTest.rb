require 'test/unit'
require 'damagecontrol/util/Timer'
require 'damagecontrol/util/Clock'
require 'damagecontrol/util/Channel'

module DamageControl

	class TimerTest < Test::Unit::TestCase
		def setup
			@clock = FakeClock.new
			@channel = Channel.new
			@timer = Timer.new {
				@channel.publish_message("message")
			}
			@timer.clock = @clock
		end
		
		def test_trigger
			@timer.interval = 10
			@clock.change_time(5)
			@timer.first_tick(@clock.current_time)
			assert_equal(15, @timer.next_tick)
			assert_nil(@channel.last_message)

			@clock.change_time(15)
			@timer.tick(@clock.current_time)
			@channel.wait_for_next_publication if @channel.last_message == nil
			assert_equal("message", @channel.last_message)
			
			assert_nil(@timer.error)
		end
		
	end
		
end
