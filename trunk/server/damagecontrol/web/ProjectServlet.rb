require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/scm/SCMFactory'

module DamageControl
  class ProjectServlet < AbstractAdminServlet
    def initialize(type, build_history_repository, project_config_repository, trigger, build_scheduler)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @trigger = trigger
      @scm_factory = SCMFactory.new
    end
    
    def default_action
      build_details
    end
    
    def dashboard
      last_completed_build = build_history_repository.last_completed_build(project_name)
      last_status = build_status(last_completed_build)

      current_build = build_history_repository.current_build(project_name)
      current_status = build_status(current_build)

      render("project_dashboard.erb", binding)
    end
    
    def trig_build
      assert_private
      @trigger.trig(project_name, Build.format_timestamp(Time.now))
      sleep 0.5
      dashboard_redirect
      render("project_dashboard.erb", binding)
    end
  
    def search
      search_string = request.query['search']
      regexp = Regexp.new(search_string, Regexp::IGNORECASE)
      
      required_project_name = request.query['project_name']
      current_build = build_history_repository.current_build(project_name)
      current_status = build_status(current_build)
      builds = build_history_repository.search(regexp, required_project_name)
      find_method = "search"
      
      render("search_results.erb", binding)
    end
    
    def build_details
      if selected_build then
        render("build_details.erb", binding)
      else
        render("never_built.erb", binding)
      end
    end
    
  protected
  
    def search_form(params)
      project_name = params[:project_name] || required_param(:project_name)
      erb("components/search_form.erb", binding)
    end
    
    def tasks
      result = super
      unless project_name.nil?
        result +=
          [
            search_form(:project_name => project_name)
          ]
        if(private?)
          result +=
            [
              task(:icon => "icons/wrench.png", :name => "Configure", :url => "configure?project_name=#{project_name}&action=configure"),
              task(:icon => "icons/gears_run.png", :name => "Trig build now", :url => "?project_name=#{project_name}&action=trig_build"),
              task(:icon => "icons/gear_connection.png", :name => "Install trigger", :url => "install_trigger?project_name=#{project_name}")
            ]
        end
        result +=
          [
            task(:icon => "icons/folders.png", :name => "Working files", :url => "root/#{project_name}/checkout"),
          ]
      end
      result
    end

    def navigation
      builds_table(
          :header_text => "Build history", 
          :empty_text => "Never built", 
          :css_class => "pane",
          :selected_build => selected_build,
          :builds => builds)
    end
  
  private
  
    def build_description(build)
      label = "##{build.label}"; 
      label = build.status if label == "#"
      "#{build.timestamp_for_humans} (#{label})"
    end

    def dashboard_redirect
      action_redirect(:dashboard, { "project_name" => project_name })
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
    
    def selected_build
      timestamp = request.query['timestamp']
      if timestamp then
        build_history_repository.lookup(project_name, request.query['timestamp'])
      else
        last_build
      end
    end
    
    def last_build
      builds[-1]
    end
    
    def builds
      build_history_repository.history(project_name)
    end
    
  end
end
