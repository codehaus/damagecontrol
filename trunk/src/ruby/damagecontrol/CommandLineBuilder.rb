module DamageControl
	
	class CommandLineBuilder
		
		def initialize(hub)
			@hub = hub
		end
		
		def receive_message(message)
			if message.is_a? BuildRequestEvent
				result = ""
				IO.popen(message.project.build_command_line) {|f| result = f.gets}
				@hub.publish_message(BuildCompleteEvent.new(message.project, result))
			end
		end
		
	end
	
end