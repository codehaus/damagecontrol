module DamageControl
	class BuildProgressEvent
		attr_reader :build
		attr_reader :output
	
		def initialize(build, output)
			@build = build
			@output = output
		end

		def ==(event)
			event.is_a?(self.class) \
				&& event.build == build \
				&& event.output == output
		end
	end
end