require 'damagecontrol/scm/AbstractTracker'
require 'damagecontrol/util/FileUtils'

module DamageControl
	class Bugzilla  < AbstractTracker
		include FileUtils
		
		public
			attr_accessor :bugzilla_url
			
			def name
				"Bugzilla"
			end
			
			def highlight(message)
				url = ensure_trailing_slash(bugzilla_url)
				if (url)
					message.gsub(Regexp.new("#([0-9]+)"),"<a href=\"" << url << "show_bug.cgi?id=\\1\">#\\1</a>")
				else
					message
				end
			end
	end
end
