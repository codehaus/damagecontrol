require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl  
  class DashboardServlet < AbstractAdminServlet
    def initialize(build_history_repository, project_config_repository, build_scheduler, type)
      super(type, build_scheduler, build_history_repository)
      @project_config_repository = project_config_repository
      
      @template_dir = File.expand_path(File.dirname(__FILE__))
    end
    
    def title
      "Dashboard"
    end
    
    def tasks
      return {} unless private?
      {
        "New project" => "project?action=configure"
      }
    end
  
    def default_action
      project_name = nil
      render("dashboard.erb", binding)
    end
    
  protected
    
  private
    
    attr_reader :project_config_repository
    
  end
end
