require 'damagecontrol/BuildEvents'
require 'damagecontrol/scm/DefaultSCMRegistry'

module DamageControl
	
	class NilSCM < SCM
		def handles_path?(path)
			true
		end
		
		def checkout(path, directory)
		end
	end
	
	# This class asks the SCM to check out latest, then
	# executes the build command.
	#
	# Consumes: BuildRequestEvent
	# Emits: BuildProgressEvent, BuildCompleteEvent
	#
	class BuildExecutor
		attr_accessor :scm
				
		def initialize(hub, scm=DefaultSCMRegistry.new)
			@hub = hub
			@scm = scm
			hub.add_subscriber(self)
		end
		
		def receive_message(message)
			if message.is_a? BuildRequestEvent
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
	
	private
	
		def report_complete
			@hub.publish_message(BuildCompleteEvent.new(@current_build))
		end


		def report_progress (line)
			@hub.publish_message(BuildProgressEvent.new(@current_build, line))
		end
	end
	
end