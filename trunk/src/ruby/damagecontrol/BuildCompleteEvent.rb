module DamageControl

	class BuildCompleteEvent
		attr_accessor :result
		
		def initialize(result)
			@result = result
		end
		
		def ==(obj)
			obj.result == result
		end
	end
end