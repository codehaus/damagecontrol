module DamageControl
	class BuildEvent
		attr_reader :build

		def initialize(build)
			@build = build
		end

		def ==(event)
			event.is_a?(self.class) && event.build == build
		end
	end
	
	class BuildProgressEvent < BuildEvent
		attr_reader :output
	
		def initialize(build, output)
			super(build)
			@output = output
		end

		def ==(event)
			super(event) && event.output == output
		end
	end

	class BuildRequestEvent < BuildEvent
	end

	class BuildCompleteEvent < BuildEvent
	end
end