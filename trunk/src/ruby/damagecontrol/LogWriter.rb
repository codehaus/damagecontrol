require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/BuildProgressEvent'
require 'damagecontrol/BuildCompleteEvent'
require 'damagecontrol/Clock'

module DamageControl

	class LogWriter
		attr_reader :current_log
		attr_accessor :clock
	
		def initialize (hub)
			@clock = Clock.new
			hub.add_subscriber(self)
		end
		
		def receive_message (message)

			if message.is_a? BuildRequestEvent
				log = "#{clock.current_time}.log"
				puts "#{self} opening log #{log}"
				@current_log = File.open(message.build.log_file(log), "w")
			end
			
			if message.is_a? BuildProgressEvent
				current_log.puts(message.output)
			end

			if message.is_a? BuildCompleteEvent
				current_log.close
			end
			
		end
	end

end