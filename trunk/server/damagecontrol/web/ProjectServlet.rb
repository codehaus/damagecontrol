require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/scm/SCMFactory'

module DamageControl
  class ProjectServlet < AbstractAdminServlet
    def initialize(build_history_repository, project_config_repository, trigger, type, build_scheduler, project_directories, trig_xmlrpc_url)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @trigger = trigger
      @project_directories = project_directories
      @trig_xmlrpc_url = trig_xmlrpc_url

      @scm_factory = SCMFactory.new
      @template_dir = File.expand_path(File.dirname(__FILE__))
    end

    def title
      "Project"
    end
    
    def search_form(params)
      project_name = params[:project_name] || required_param(:project_name)
      erb("components/search_form.erb", binding)
    end
    
    def sidepanes
      result = super
      unless project_name.nil?
        result +=
          [
            search_form(:project_name => project_name)
          ]
        if(private?)
          result +=
            [
              task(:name => "Configure", :url => "?project_name=#{project_name}&action=configure"),
              task(:name => "Trig build now", :url => "?project_name=#{project_name}&action=trig_build"),
              task(:name => "Install trigger", :url => "?project_name=#{project_name}&action=install_trigger")
            ]
        end
        result +=
          [
            task(:name => "Working files", :url => "root/#{project_name}/checkout"),
            builds_table(
                :header_text => "Build history", 
                :empty_text => "Never built", 
                :css_class => "pane",
                :selected_build => selected_build,
                :builds => builds)
          ]
      end
      result
    end
  
    def default_action
      build_details
    end
    
    def configure
      assert_private
      action = "store_configuration"
      project_config = {}
      project_config = @project_config_repository.project_config(project_name) if @project_config_repository.project_exists?(project_name)
      render("configure.erb", binding)
    end
    
    KEYS = [
      "build_command_line", 
      "project_name", 
      "unix_groups",
      "view_cvs_url",
      "trigger", 
      "nag_email", 
      "scm_type", 
      "cvsroot", 
      "cvsmodule", 
      "cvspassword", 
      "svnurl"
    ]
    
    def install_trigger
      # Uninstall the old trigger (if any)
      project_config = @project_config_repository.project_config(project_name)
      scm = @scm_factory.get_scm(project_config, @project_directories.checkout_dir(project_name))
      error = nil
      begin
        scm.uninstall_trigger(project_name) if scm.trigger_installed?(project_name)
  
        # Install the trigger if trigger=xmlrpc
        trigger_type = project_config["trigger"]
        if trigger_type == "xmlrpc"
          scm.install_trigger(project_name, @trig_xmlrpc_url)
        else
          raise "can't install trigger type: #{trigger_type}"
        end
      rescue Exception => e
        error = e
      end
      render("trigger_installed.erb", binding)
    end
    
    def store_configuration
      assert_private
      @project_config_repository.new_project(project_name) unless @project_config_repository.project_exists?(project_name)
      project_config = @project_config_repository.project_config(project_name)
      
      # copy the key/values from the request over to the project_config
      # request.each do |key, value| won't work - it takes too much.
      KEYS.each do |key|
        project_config[key] = request.query[key]
      end

      @project_config_repository.modify_project_config(project_name, project_config)
      
      dashboard_redirect
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
      dashboard_redirect
      render("project_dashboard.erb", binding)
    end
  
    def search
      criterion = request.query['search']
      required_project_name = request.query['project_name']
      current_build = build_history_repository.current_build(project_name)
      current_status = build_status(current_build)
      builds = build_history_repository.search(criterion, required_project_name)
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

    def build_description(build)
      label = "##{build.label}"; 
      label = build.status if label == "#"
      "#{build.timestamp_for_humans} (#{label})"
    end

  private
    
    def dashboard_redirect
      action_redirect(:dashboard, { "project_name" => project_name })
    end
    
    def project_name
      request.query['project_name']
    end
    
  end
end
