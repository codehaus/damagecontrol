module DamageControl
	class AbstractTracker
		public
		
			def can_create?
				false
			end
			
			def exists?
				true
			end
			
			def supports_trigger?
				false
			end
			
			def highlight(message)
				message
			end
	end
end
