module DamageControl
	class BuildRequestEvent
		attr_reader :project
		
		def initialize( project )
			@project = project
		end
	end
end