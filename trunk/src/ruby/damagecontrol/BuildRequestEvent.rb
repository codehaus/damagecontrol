module DamageControl
	class BuildRequestEvent
		attr_reader :project
		
		def initialize( project )
			@project = project
		end
		
		def ==(other)
			@project == other.project
		end
		
	end
end