require 'damagecontrol/Timer'

module DamageControl
	class AsyncComponent
		attr_reader :hub
		
		include TimerMixin
		
		def initialize(hub)
			super()
			@inq = []
			@hub = hub
			hub.add_subscriber(self)
		end

		def tick(time)
			schedule_next_tick
			process_messages
		end
		
		def process_messages
			# process copy of array so that process_message can remove entries via consume
			@inq.clone.each {|message| process_message(message) }
		end

		def consume_message(message)
			@inq.delete(message)
		end
		
		def enq_message(message)
			@inq.push(message)
		end
	
		def receive_message(message)
			enq_message(message)
		end
		
		def consumed_message?(message)
			!@inq.index(message)
		end
	end
end