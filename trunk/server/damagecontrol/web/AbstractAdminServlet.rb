require 'webrick'
require 'pebbles/MVCServlet'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/Logging'
require 'damagecontrol/Version'

module DamageControl
  class AbstractAdminServlet < Pebbles::MVCServlet
    
    include Logging
  
    def initialize(type, build_scheduler, build_history_repository, project_config_repository)
      @type = type
      @build_scheduler = build_scheduler
      @build_history_repository = build_history_repository
      @project_config_repository = project_config_repository
    end
    
    def create_scm_repository
      # Instantiate the SCM object
      scm = project_config_repository.create_scm(project_name)
      # Create the repo on disk
      scm.create
      action_redirect(:configure, { "project_name" => project_name })
    end

  protected
  
    attr_reader :build_history_repository
    attr_reader :project_config_repository
    attr_reader :build_scheduler

    def project_name
      # Use path info instead of query string, this makes better access control possible
      # but query string takes precedence before path info in order to enable project cloning
      request.path_info[1..-1]
    end
    
    def project_exists?
      @project_config_repository.project_exists?(project_name)
    end
    
    def project_config
      return @project_config_repository.default_project_config("") unless project_exists?
      @project_config_repository.project_config(project_name)
    end
    
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
    
    def tasks
      result = [] 
      if private?
        configpath = "configure"
        configpath = "../configure" if toplevel
        result += [
          task(:icon => "largeicons/box_new.png", :name => "New project", :url => configpath)
        ]
      else 
      end
      result
    end
    
    def search_form
      global_search_form
    end
    
    def global_search_form
      erb("components/global_search_form.erb", binding)
    end
    
    def navigation
      ""
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
    
    def toplevel
      !request.path_info.empty?
    end
    
    def breadcrumbs
      result = "<a href=\"dashboard\">Dashboard</a>"
      result = "<a href=\"../dashboard\">Dashboard</a>" if toplevel
      result << " > <a href=\"../project/#{project_name}\">#{project_name}</a>" if toplevel
      result
    end
    
    def build_description(build)
      label = "##{build.label}"; 
      label = build.status if label == "#"
      "#{build.dc_creation_time.to_human} (#{label})"
    end

    def builds_table(params)
      header_text = params[:header_text] || "Builds"
      empty_text = params[:empty_text] || "No builds"
      css_class = params[:css_class] || "builds"
      builds = params[:builds] || required_param(:builds)
      selected_build = params[:selected_build] || nil
      base_url = params[:base_url] || ""
      prefix_with_project_name = params[:prefix_with_project_name] == true || false
      max_number_of_builds = params[:max_number_of_builds] || default_number_of_builds
      erb("components/builds_table.erb", binding)
    end

    def rss_url
      nil
    end
    
    def default_number_of_builds
      30
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
    
    def extra_css
      []
    end
    
  private
    def build_url(build)
      return nil unless build
      "{build.project_name}?dc_creation_time=#{build.dc_creation_time.ymdHMS}"
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
