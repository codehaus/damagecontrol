require 'webrick'
require 'pebbles/MVCServlet'

module DamageControl
  class AbstractAdminServlet < Pebbles::MVCServlet
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
    
    def tasks
      {}
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
    
    def scm_url(project_name, modification)
      view_cvs_url = project_config_repository.project_config(project_name)["view_cvs_url"]
      return nil if view_cvs_url.nil?
      view_cvs_url_patched = "#{view_cvs_url}/" if(view_cvs_url && view_cvs_url[-1..-1] != "/")
      if(view_cvs_url)
        url = "#{view_cvs_url_patched}#{path}"
        url << "?r1=#{modification.revision}&r2=#{modification.previous_revision}" if(modification.previous_revision)
        path = "<a href=\"#{url}\">#{modification.path}</a>"
      end
    end
    
    def builds_table(params)
      header_text = params[:header_text] || "Builds"
      empty_text = params[:empty_text] || "No builds"
      css_class = params[:css_class] || "builds"
      builds = params[:builds] || required_param(:builds)
      prefix_with_project_name = params[:prefix_with_project_name] == true || false
      erb("components/builds_table.erb", binding)
    end
    
    def required_param(param)
      raise "required keyed parameter #{param.inspect}"
    end
    
  private
    
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
  
  end
end
