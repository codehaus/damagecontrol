require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl  
  class DashboardServlet < AbstractAdminServlet
    def initialize(type, build_history_repository, project_config_repository, build_scheduler)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @project_config_repository = project_config_repository
    end
    
    def default_action
      render("dashboard.erb", binding)
    end
    
  protected
    
    def global_search_form
      erb("components/global_search_form.erb", binding)
    end
    
    def project_status
      erb("components/project_status.erb", binding)
    end
    
    def build_queue
      build_queue = build_scheduler.build_queue.sort {|b1, b2| b1.timestamp_as_time == b2.timestamp_as_time }
      erb("components/build_queue.erb", binding)
    end
    
    def build_executor_status_message(build_executor)
      status = ""
      if build_executor.busy? then
        status = "Building #{build_executor.scheduled_build.project_name}"
      else
        status = "Idle"
      end
    end
    
    def build_executor_status
      build_executors = build_scheduler.executors
      erb("components/build_executor_status.erb", binding)
    end
    
    def tasks
      result = super
      result += [ global_search_form ]
      result
    end
    
    def title
      "Dashboard"
    end
    
    def navigation
      ""
    end
  
  private
    
  end
end
