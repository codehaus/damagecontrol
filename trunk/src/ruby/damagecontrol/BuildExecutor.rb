require 'damagecontrol/BuildEvents'
require 'damagecontrol/scm/SCM'

module DamageControl
	
	class NilSCM < SCM
		def handles_path?(path)
			true
		end
		
		def checkout(path, directory)
		end
	end
	
	class BuildExecutor
		attr_accessor :scm
				
		def initialize(hub, scm=NilSCM.new)
			@hub = hub
			hub.add_subscriber(self)
			@scm = scm
		end
		
		def receive_message(message)
			if message.is_a? BuildRequestEvent
				puts "building #{message.build.project_name}"
				@current_build = message.build
				scm.checkout(@current_build.scm_path, @current_build.basedir) do |progress|
					report_progress(progress)
				end
				@current_build.successful = @current_build.build do |progress|
					report_progress(progress)
				end
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