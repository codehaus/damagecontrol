require 'webrick'
require 'pebbles/MVCServlet'
require 'damagecontrol/scm/Changes'

module DamageControl
  class AbstractAdminServlet < Pebbles::MVCServlet
    
    include Logging
  
    def initialize(type, build_scheduler, build_history_repository, project_config_repository)
      @type = type
      @build_scheduler = build_scheduler
      @build_history_repository = build_history_repository
      @project_config_repository = project_config_repository
    end
    
  protected
  
    attr_reader :build_history_repository
    attr_reader :project_config_repository
    attr_reader :build_scheduler

    def template_dir
      File.expand_path(File.dirname(__FILE__))
    end
    
    def auto_refresh_rate
      10
    end
  
    def auto_refresh?
      to_boolean(request.query['auto_refresh'])
    end
    
    def auto_refresh_url_prefix
      query_string = request.query_string
      return "?" if query_string.nil?
      query_string.gsub!(/&?auto_refresh=.*&?/, "")
      return "?" if query_string == ""
      "?#{query_string}&"
    end
    
    def title
      ""
    end
    
    def sidepanes
      []
    end
    
    def ritemesh_template
      "decorators/default.erb"
    end
    
    def assert_private
      raise "not privileged" if @type != :private
    end
  
    def private?
      @type == :private
    end
    
    def breadcrumbs
      result = "<a href=\"dashboard\">Dashboard</a>"
      result << " > <a href=\"project?project_name=#{project_name}\">#{project_name}</a>" if request.query['project_name']
      result
    end
    
    def scm_url(project_name, change)
      scm = SCMFactory.new.get_scm(project_config_repository.project_config(project_name), "/dev/null")
      scm.web_url_to_change(change)
    end
    
    def builds_table(params)
      header_text = params[:header_text] || "Builds"
      empty_text = params[:empty_text] || "No builds"
      css_class = params[:css_class] || "builds"
      builds = params[:builds] || required_param(:builds)
      selected_build = params[:selected_build] || nil
      prefix_with_project_name = params[:prefix_with_project_name] == true || false
      erb("components/builds_table.erb", binding)
    end
    
    def task(params)
      icon = params[:icon] # || required_param(:icon)
      url = params[:url] || required_param(:url)
      name = params[:name] || required_param(:name)
      erb("components/task.erb", binding)
    end
    
    def required_param(param)
      raise "required keyed parameter #{param.inspect}"
    end
    
    def file_icon(change)
      icon = FILE_ICONS[change.status]
      icon = "fileicons/document_warning.png" unless icon
      icon
    end
    
  private
    FILE_ICONS = {
      Change::MODIFIED => "fileicons/document_edit.png",
      Change::DELETED  => "fileicons/document_delete.png",
      Change::ADDED    => "fileicons/document_new.png",
      Change::MOVED    => "fileicons/document_exchange.png"
    }
    
    def build_url(build)
      return nil unless build
      "?action=build_details&project_name=#{build.project_name}&timestamp=#{build.timestamp}"
    end
    
    def build_status(build)
      return "Never built" if build.nil?
      build.status
    end

    def to_boolean(text)
      text && text == "true"
    end
    
    # i18n
    def no_changes_in_this_build
      "No changes in this build"
    end
  
  end
end
