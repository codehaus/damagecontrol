module DamageControl

	class BuildCompleteEvent
		attr_reader :result
		attr_reader :project

		def initialize( project, result )
			@project = project
			@result = result
		end
		
		def ==(event)
			event.result == result && event.project == project
		end
	end

end