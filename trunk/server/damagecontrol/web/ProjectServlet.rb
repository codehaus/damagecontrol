require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class ProjectServlet < AbstractAdminServlet
    def initialize(build_history_repository, project_config_repository, trigger, type)
      super(type)
      @build_history_repository = build_history_repository
      @project_config_repository = project_config_repository
      @trigger = trigger
    end

    def templatedir
      File.dirname(__FILE__)
    end
  
    def title
      "Project"
    end
    
    def tasks
      return {} unless private?
      {
        "Configure" => "?project_name=#{project_name}&action=configure",
        "Trig build now" => "?project_name=#{project_name}&action=trig_build"
      }
    end
  
    def default_action
      dashboard
    end
    
    def configure
      assert_private
      action = "store_configuration"
      project_config = {}
      project_config = @project_config_repository.project_config(project_name) if @project_config_repository.project_exists?(project_name)
      render("configure.erb", binding)
    end
    
    KEYS = ["build_command_line", "project_name", "unix_groups", "scm_type", "cvsroot", "cvsmodule", "cvspassword", "svnurl"]
    
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
    
    def dashboard
      last_status = build_status(@build_history_repository.last_completed_build(project_name))
      current_status = build_status(@build_history_repository.current_build(project_name))
      cvsroot = request.query['cvsroot']
      render("project_dashboard.erb", binding)
    end
    
    def trig_build
      assert_private
      @trigger.trig(project_name, Build.format_timestamp(Time.now))
      dashboard_redirect
    end
  
  private
  
    def dashboard_redirect
      action_redirect(:dashboard, { "project_name" => project_name })
    end
    
    def build_status(build)
      return "Never built" if build.nil?
      build.status
    end

    def project_name
      request.query['project_name']
    end
    
  end
end
