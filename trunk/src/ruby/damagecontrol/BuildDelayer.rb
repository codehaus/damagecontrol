require 'test/unit'

require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Project'
require 'damagecontrol/FakeClock'

module DamageControl

	class BuildDelayer
		attr_accessor :quiet_period
		attr_accessor :clock
		
		include TimerMixin
	
		def initialize(receiver)
			@clock = Clock.new
			@receiver = receiver
			@quiet_period = quiet_period
		end
		
		def receive_message(message)
			clock.register(self)
			@last_message = message
			@last_message_time = @clock.current_time
		end
		
		def tick(time)
			if nil|@last_message && time > @last_message_time + quiet_period
				@receiver.receive_message( @last_message )
				clock.unregister(self)
			end
		end
	end
	
end