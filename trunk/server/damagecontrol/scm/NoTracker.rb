require 'damagecontrol/scm/AbstractTracker'

module DamageControl
	class NoTracker < AbstractTracker
		public
		
			def name
				"No Tracker"
			end
			
			def ==(other_scm)
      return false if self.class != other_scm.class
      true
    end
	end
end
