require 'damagecontrol/CruiseControlLogPoller'

module DamageControl

	class BuildCompleteEvent
		attr_reader :build

		def initialize (build)
			@build = build
		end
		
		def ==(event)
			event.is_a?(BuildCompleteEvent) \
				&& event.build == build
		end
	end

end