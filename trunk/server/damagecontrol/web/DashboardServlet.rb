require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl  
  class DashboardServlet < AbstractAdminServlet
    def initialize(build_history_repository, project_config_repository, type)
      super(type)
      @build_history_repository = build_history_repository
      @project_config_repository = project_config_repository
    end
    
    def templatedir
      File.dirname(__FILE__)
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
      render("dashboard.erb", binding)
    end
    
    protected
    
    private
    
    attr_reader :build_history_repository
    attr_reader :project_config_repository
    
  end
end
