require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl  
  class DashboardServlet < AbstractAdminServlet
    def initialize(build_history_repository, project_config_repository, build_scheduler, type)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @project_config_repository = project_config_repository
    end
    
    def title
      "Dashboard"
    end
    
    def global_search_form
      erb("components/global_search_form.erb", binding)
    end
    
    def sidepanes
      result = super
      result +=
        [
          global_search_form
        ]
      if private?
        result +=
          [
            task(:name => "New project", :url => "project?action=configure")
          ]
      end
      result
    end
  
    def default_action
      render("dashboard.erb", binding)
    end
    
  protected
    
  private
    
  end
end
