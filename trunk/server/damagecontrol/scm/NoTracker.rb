require 'damagecontrol/scm/AbstractTracker'

module DamageControl
	class NoTracker < AbstractTracker
		public
		
			def name
				"No Tracker"
			end
	end
end
