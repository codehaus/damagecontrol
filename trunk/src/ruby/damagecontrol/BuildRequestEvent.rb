module DamageControl
	class BuildRequestEvent
		attr_reader :build
		
		def initialize( build )
			@build = build
		end
		
		def ==(other)
			@build == other.build
		end
		
	end
end