require 'test/unit'

require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Project'
require 'damagecontrol/FakeClock'

module DamageControl

	class BuildDelayer
	
		def initialize(clock, receiver, safe_delay)
			@clock = clock
			@receiver = receiver
			@safe_delay = safe_delay
			clock.register(self)
		end
		
		def receive_message(message)
			@last_message = message
			@last_message_time = @clock.current_time
		end
		
		def tick(time)
			if nil|@last_message && time > @last_message_time + @safe_delay
				@receiver.receive_message( @last_message )
			end
		end
	end
	
end