require 'damagecontrol/Clock'
require 'damagecontrol/Latch'

module DamageControl

	class Hub
		attr_reader :last_message
		attr_accessor :clock
		
		def initialize
			@clock = Clock.new
			@subscribers = Array.new
			@publication = Latch.new
		end
		
		
		def wait_for_next_publication (timout=-1)
			@publication.wait
		end
		
		def publish_message(message)
			puts "publishing message #{message} at time #{clock.current_time}"
			@last_message=message
			@subscribers.each {|subscriber|
				subscriber.receive_message(message)
			}
			@publication.release
			@publication = Latch.new
		end
		
		def add_subscriber(subscriber)
			@subscribers << subscriber
		end
	end

end