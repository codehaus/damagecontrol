require 'damagecontrol/web/Report'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class Icon
    def initialize(name, description)
      @name = name
      @description = description
    end
    
    def url
      "smallicons/#{@name}.png"
    end
    
    def alt
      @description
    end
    
    def to_s
      url
    end
    
    def size
      16
    end
    
    def width
      size
    end
    
    def height
      size
    end
    
    def render
      "<img width=\"#{width}\" height=\"#{height}\" src=\"#{url}\" title=\"#{alt}\" />"
    end
  end

  class ChangesReport < Report
    include Pebbles::HTMLQuoting
    include FileUtils

    def id
      "changes"
    end
    
    def icon
      "smallicons/document_exchange.png"
    end
    
    def content
      changesets = selected_build.changesets
      no_changes_in_this_build =
        %{No changes in this build (this could happen because the build was manually trigged,
the working directory has been cleaned out, or because there has been no successful builds for this project yet)}
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

      return "root/#{project_name}/checkout/#{change.path}" if scm_web_url.nil? || scm_web_url == "" 

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
      Change::MODIFIED => Icon.new("document_edit", "Edited - the file was changed in this changeset"),
      Change::DELETED => Icon.new("document_delete", "Deleted - the file was removed in this changeset"),
      Change::ADDED => Icon.new("document_new", "Added - the file was added in this changeset"),
      Change::MOVED  => Icon.new("document_exchange", "Moved - the file was moved in this changeset")
    }
    
  end
end