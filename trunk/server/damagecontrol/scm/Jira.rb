require 'damagecontrol/scm/AbstractTracker'
require 'damagecontrol/util/FileUtils'

module DamageControl
	class Jira  < AbstractTracker
		include FileUtils
		
		public
			attr_accessor :jira_url
			
			def highlight(message)
				url = ensure_trailing_slash(jira_url)
				if(url)
        	message.gsub!(/^([A-Z]+-[0-9]+)/, "<a href=\"#{url}browse/\\1\">\\1</a>")
					message.gsub!(/(.*[\s])+([A-Z]+-[0-9]+)/, "\\1<a href=\"#{url}browse/\\2\">\\2</a>")
					message
				else
        	message
				end
			end
	end
end
