require 'damagecontrol/CruiseControlLogPoller'

module DamageControl

	class BuildCompleteEvent
		attr_reader :project
		attr_accessor :build

		def initialize (project)
			@project = project
			@build = Build.new
		end
		
		def ==(event)
			event.is_a?(BuildCompleteEvent) \
				&& event.project == project
		end
	end

end