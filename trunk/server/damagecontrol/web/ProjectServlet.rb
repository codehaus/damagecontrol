require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/scm/SCMFactory'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/web/ConsoleOutputReport'
require 'damagecontrol/web/ChangesReport'

module DamageControl
  class ProjectServlet < AbstractAdminServlet
    include FileUtils
  
    def initialize(type, build_history_repository, project_config_repository, trigger, build_scheduler)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @trigger = trigger
    end
    
    def default_action
      build_details
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
      sleep 0.5
      dashboard_redirect
      render("project_dashboard.erb", binding)
    end
  
    def build_details
      if selected_build
        render("build_details.erb", binding)
      else
        render("never_built.erb", binding)
      end
    end
    
  protected

    def reports
      [
        ChangesReport.new(selected_build, project_config_repository),
        ConsoleOutputReport.new(selected_build, project_config_repository)
      ]
    end
    
    def selected_report
      id = selected_report_id
      reports.find {|t| id == t.id }
    end
    
    def selected_report_id
      request.query["report"] || default_report_id
    end
    
    def default_report_id
      "changes"
    end
    
    def tasks    
      result = super
      unless project_name.nil?
        if(private?)
          result +=
            [
              task(:icon => "icons/box_into.png", :name => "Clone project", :url => "configure?project_name=#{project_name}&action=clone_project"),
              task(:icon => "icons/wrench.png", :name => "Configure", :url => "configure?project_name=#{project_name}&action=configure"),
              task(:icon => "icons/gears_run.png", :name => "Trig build now", :url => "?project_name=#{project_name}&action=trig_build"),
              task(:icon => "icons/gear_connection.png", :name => "Install trigger", :url => "install_trigger?project_name=#{project_name}"),
            ]
        end
        result +=
          [
            task(:icon => "icons/folders.png", :name => "Working files", :url => "root/#{project_name}/checkout"),
          ]
        prev_build = build_history_repository.prev(selected_build)
        if(prev_build)
          result +=
            [
                task(:icon => "icons/navigate_left.png", :name => "Previous build", :url => build_url(prev_build))
            ]
        end
        next_build = build_history_repository.next(selected_build)
        if(next_build)
          result +=
            [
                task(:icon => "icons/navigate_right.png", :name => "Next build", :url => build_url(next_build))
            ]
        end
      end
      result
    end
    
    def search_form
      if project_name
        project_search_form(:project_name => project_name)
      else
        super
      end
    end
    
    def project_search_form(params)
      project_name = params[:project_name] || required_param(:project_name)
      erb("components/search_form.erb", binding)
    end
    
    def navigation
      builds_table(
          :header_text => "Build history", 
          :empty_text => "Never built", 
          :css_class => "pane",
          :selected_build => selected_build,
          :builds => build_history)
    end
  
  private
  
    def dashboard_redirect
      action_redirect(:dashboard, { "project_name" => project_name })
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
      build_history_repository.history(project_name)[-1]
    end
    
    def build_history
      history = build_history_repository.history(project_name)
      current_build = build_history_repository.current_build(project_name)
      history.delete_if {|b| b != current_build && !b.completed?}
      history
    end
    
  end
end
