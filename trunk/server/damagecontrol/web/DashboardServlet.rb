require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/web/ProjectStatus'

module DamageControl  
  class DashboardServlet < AbstractAdminServlet
    def initialize(type, build_history_repository, project_config_repository, build_scheduler)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @project_config_repository = project_config_repository
    end
    
    def default_action
      dashboard
    end
    
    def kill_executor
      assert_private
      executor_index = request.query["executor"].to_i
      build_scheduler.executors[executor_index].kill_build_process
      action_redirect(:dashboard)
    end
    
    def dashboard
      render("dashboard.erb", binding)
    end
    
  protected
  
    def project_status
      project_statuses = project_config_repository.project_names.collect {|n| ProjectStatus.new(n, build_history_repository)}
      erb("components/project_status.erb", binding)
    end
    
    def build_scheduler_status(build_scheduler)
      build_executors = build_scheduler.executors
      build_queue = build_scheduler.build_queue.sort {|b1, b2| b1.timestamp_as_time <=> b2.timestamp_as_time }
      erb("components/build_scheduler_status.erb", binding)
    end
    
    def title
      "Dashboard"
    end
    
    def navigation
      build_scheduler_status(build_scheduler)
    end
  
  private
    
  end
end
