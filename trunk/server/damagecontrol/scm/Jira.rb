require 'damagecontrol/scm/AbstractTracker'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class Jira  < AbstractTracker
    include FileUtils
    
    attr_accessor :jira_url
    attr_accessor :jira_project_id

    def name
      "JIRA"
    end
    
    def url
      "#{ensure_trailing_slash(jira_url)}browse/#{jira_project_id}"
    end

    def highlight(message)
      url = ensure_trailing_slash(jira_url)
      if(url)
	message.gsub(/(?:^|\s)+([A-Z]+-[0-9]+)/, "<a href=\"#{url}browse/\\1\">\\1</a>")
      else
        message
      end
    end
  end
end
