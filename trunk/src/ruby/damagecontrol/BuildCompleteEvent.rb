module DamageControl

	class BuildCompleteEvent
		attr_reader :project
		attr_accessor :build

		def initialize (project)
			@project = project
		end
		
		def ==(event)
			event.is_a?(BuildCompleteEvent) \
				&& event.project == project
		end
	end

end