require 'damagecontrol/web/Report'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/Changes'
require 'pebbles/MVCServlet'

module DamageControl
  class ChangesReport < Report
    include Pebbles::HTMLQuoting
    include FileUtils

    def id
      "changes"
    end
    
    def icon
      "icons/document_edit.png"
    end
    
    def content
      changesets = selected_build.changesets
      no_changes_in_this_build = "No changes in this build"
      erb("components/changes.erb", binding)
    end
    
    def quote_message(message)
      m = html_quote(message)
      jira_url = ensure_trailing_slash(project_config["jira_url"])
      if(jira_url)
        m.gsub(/([A-Z]+-[0-9]+)/, "<a href=\"#{jira_url}browse/\\1\">\\1</a>")
      else
        m
      end
    end

    private
    
    # Works with ViewCVS
    def web_url_to_change(change)
      scm_web_url = project_config["scm_web_url"]

      # TODO better handling of working dir for the file
      return "root/#{project_name}/checkout/#{project_name}/#{change.path}" if scm_web_url.nil? || scm_web_url == "" 

      scm_web_url = ensure_trailing_slash(scm_web_url)
      url = "#{scm_web_url}#{change.path}"
      
      if(change.previous_revision)
        # point to the viewcvs and fisheye diffs (if we know the previous revision)
        url << "?r1=#{change.previous_revision}&r2=#{change.revision}"
      else
        # point to the viewcvs (rev) and fisheye (r) revisions (no diff view)
        url << "?rev=#{change.revision}&r=#{change.revision}"
      end
      
      url
    end
    
    def file_icon(change)
      icon = FILE_ICONS[change.status]
      icon = "fileicons/document_warning.png" unless icon
      icon
    end
    
    FILE_ICONS = {
      Change::MODIFIED => "fileicons/document_edit.png",
      Change::DELETED  => "fileicons/document_delete.png",
      Change::ADDED    => "fileicons/document_new.png",
      Change::MOVED    => "fileicons/document_exchange.png"
    }
    
  end
end