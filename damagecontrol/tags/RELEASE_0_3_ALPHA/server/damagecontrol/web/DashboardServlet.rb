require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/web/ProjectStatus'
require 'damagecontrol/web/BuildExecutorStatus'

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
      executor_name = request.query["executor"]
      build_scheduler.kill_named_executor(executor_name)
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
      i = -1
      build_executors = build_scheduler.executors.collect do |e|
        i+=1
        BuildExecutorStatus.new(i, e, build_history_repository)
      end
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
