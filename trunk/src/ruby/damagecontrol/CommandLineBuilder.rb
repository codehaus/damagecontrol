module DamageControl
	
	class CommandLineBuilder
		
		def initialize(hub, command_line)
			@hub = hub
			@command_line = command_line
		end
		
		def receive_message(message)
			result = ""
			IO.popen(@command_line) {|f| result = f.gets}
			@hub.publish_message(BuildCompleteEvent.new(result)) if message.is_a? BuildRequestEvent
		end
		
	end
	
end