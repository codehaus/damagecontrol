require 'test/unit'

require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Project'
require 'damagecontrol/FakeClock'
require 'damagecontrol/BuildDelayer'

module DamageControl

	class BuildDelayerTest < Test::Unit::TestCase
	
		def receive_message(msg)
			@received_message = msg
		end

		def setup
			project = Project.new("foo")
			@fakeClock = FakeTicker.new()

			@b = BuildDelayer.new(self)
			@b.quiet_period = 5000
			@b.clock = @fakeClock
			
			@msg = BuildRequestEvent.new(project)
			
			@fakeClock.set_time(2000)
			@b.receive_message(@msg)

		end
		
		def test_delayer_registers_with_clock
			clock = FakeClock.new()
			b = BuildDelayer.new(self)
			b.clock = clock
			b.receive_message("")
			assert(clock.receivers.index(b) >= 0)
		end

		def test_fires_if_gone_past_safe_delay
		
			@fakeClock.do_tick(3000)
			assert_nil( @received_message )

			@fakeClock.do_tick(8000)
			
			assert_not_nil(@received_message)
			assert_equal( @msg, @received_message )

		end
		
		def test_unregisters_after_message_passed_on
			
			@fakeClock.do_tick(8000)
			
			assert_equal([], @fakeClock.receivers)

		end
		
		def test_doesnt_fire_if_another_message_received
		
			@fakeClock.do_tick(4999)
			assert_nil( @received_message )

			@b.receive_message(@msg)

			@fakeClock.do_tick(6000)
			assert_nil( @received_message )

			@fakeClock.do_tick(11000)
			assert_not_nil(@received_message)
			assert_equal( @msg, @received_message )
		end

	end

end
