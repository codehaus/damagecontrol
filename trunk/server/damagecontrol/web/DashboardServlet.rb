require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl  
  class DashboardServlet < AbstractAdminServlet
    def initialize(type, build_history_repository, project_config_repository, build_scheduler)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @project_config_repository = project_config_repository
    end
    
    def title
      "Dashboard"
    end
    
    def global_search_form
      erb("components/global_search_form.erb", binding)
    end
    
    def tasks
      result = super
      result += [ global_search_form ]
      result
    end
    
    def navigation
      ""
    end
  
    def default_action
      render("dashboard.erb", binding)
    end
    
  protected
    
  private
    
  end
end
