module DamageControl
	class BuildProgressEvent
		attr_reader :project
		attr_reader :output
	
		def initialize(project, output)
			@project = project
			@output = output
		end

		def ==(event)
			event.is_a?(self.class) \
				&& event.project == project \
				&& event.output == output
		end
	end
end