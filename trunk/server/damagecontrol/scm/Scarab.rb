require 'damagecontrol/scm/AbstractTracker'
require 'damagecontrol/util/FileUtils'

module DamageControl
	class Scarab  < AbstractTracker
		include FileUtils
		
		public
			attr_accessor :scarab_url
			attr_accessor :module_key
			
			def name
				"Scarab"
			end
			
			def highlight(message)
				url = ensure_trailing_slash(scarab_url)
				if (url)
					message.gsub(Regexp.new("(" << module_key << "[0-9]+)"),"<a href=\"" << url << "issues/id/\\1\">\\1</a>")
				else
					message
				end
			end
	end
end
