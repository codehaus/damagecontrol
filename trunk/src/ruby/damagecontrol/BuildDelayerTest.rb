require 'test/unit'

require 'damagecontrol/BuildEvents'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/BuildDelayer'
require 'damagecontrol/Clock'

module DamageControl

	class BuildDelayerTest < Test::Unit::TestCase
	
		def receive_message(msg)
			@received_message = msg
		end

		def setup
			build = Build.new("foo")
			@fake_clock = FakeClock.new()

			@b = BuildDelayer.new(self)
			@b.quiet_period = 5000
			@b.clock = @fake_clock
			
			@msg = BuildRequestEvent.new(Build)
			
			@fake_clock.change_time(2000)
			@b.receive_message(@msg)

		end
		
		def test_doesnt_fire_before_quiet_period
			assert_nil( @received_message )
		end

		def test_fires_if_gone_past_safe_delay
		
			@b.tick(3000)
			assert_nil( @received_message )

			@b.tick(8000)
			
			assert_not_nil(@received_message)
			assert_equal( @msg, @received_message )

		end
		
		def test_doesnt_fire_if_another_message_received
		
			@b.tick(4999)
			assert_nil( @received_message )

			@b.receive_message(@msg)

			@b.tick(6000)
			assert_nil( @received_message )

			@b.tick(11000)
			assert_not_nil(@received_message)
			assert_equal( @msg, @received_message )
		end
		
		def test_reschedules_on_tick
			@b.tick(@b.clock.current_time)
			assert_equal(@b.clock.current_time + 1000, @b.next_tick)
		end

	end

end
