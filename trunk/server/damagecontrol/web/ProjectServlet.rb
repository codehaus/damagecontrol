require 'webrick'
require 'erb'
require 'pebbles/MVCServlet'

module DamageControl  
  class ProjectServlet < Pebbles::MVCServlet
    def initialize(build_history_repository, project_config_repository, trigger, type)
      @build_history_repository = build_history_repository
      @project_config_repository = project_config_repository
      @trigger = trigger
      @type = type
    end

    def templatedir
      File.dirname(__FILE__)
    end
  
    def default_action
      dashboard
    end
    
    def configure
      assert_private
      action = "store_configuration"
      project_config = {}
      project_config = @project_config_repository.project_config(project_name) if @project_config_repository.project_exists?(project_name)
      erb("configure.erb", binding)
    end
    
    def store_configuration
      assert_private
      @project_config_repository.new_project(project_name) unless @project_config_repository.project_exists?(project_name)
      project_config = @project_config_repository.project_config(project_name)
      project_config["build_command_line"] = request.query['build_command_line']
      project_config["scm_spec"] = request.query['scm_spec']
      @project_config_repository.modify_project_config(project_name, project_config)
      
      dashboard_redirect
    end
    
    def dashboard_redirect
      action_redirect(:dashboard, { "project_name" => project_name })
    end
    
    def build_status(build)
      return "Never built" if build.nil?
      build.status
    end

    def dashboard
      last_status = build_status(@build_history_repository.last_completed_build(project_name))
      current_status = build_status(@build_history_repository.current_build(project_name))
      cvsroot = request.query['cvsroot']
      erb("project_dashboard.erb", binding)
    end
    
    def trig_build
      assert_private
      @trigger.trig(project_name, Build.format_timestamp(Time.now))
      dashboard_redirect
    end
  
  private
  
    def assert_private
      raise "not privileged" if @type != :private
    end
  
    def project_name
      request.query['project_name']
    end
    
  end
end
