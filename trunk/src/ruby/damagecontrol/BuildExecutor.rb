require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/BuildProgressEvent'
require 'damagecontrol/BuildCompleteEvent'

module DamageControl
	
	class BuildExecutor
		
		def initialize(hub)
			@hub = hub
			hub.add_subscriber(self)
		end
		
		def receive_message(message)
			if message.is_a? BuildRequestEvent
				puts "building #{message.build.project_name}"
				@current_build = message.build
				@current_build.build {|progress|
					progress.each_line {|line|
						report_progress(line)
					}
				}
				report_complete
			end
		end
		
		def report_complete
			@hub.publish_message(BuildCompleteEvent.new(@current_build))
		end


		def report_progress (line)
			@hub.publish_message(BuildProgressEvent.new(@current_build, line))
		end
	end
	
end