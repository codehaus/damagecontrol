require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class ProjectServlet < AbstractAdminServlet
    include FileUtils
  
    def initialize(type, build_history_repository, project_config_repository, trigger, build_scheduler, report_classes, rss_url, trig_xmlrpc_url)
      super(type, build_scheduler, build_history_repository, project_config_repository)
      @trigger = trigger
      @report_classes = report_classes
      @rss_url = rss_url
      @trig_xmlrpc_url = trig_xmlrpc_url
    end
    
    def default_action
      build_details
    end
    
    def trig_build
      assert_private
      @trigger.request(project_name)
      sleep 0.5
      build_details_redirect
    end
  
    def build_details
      if selected_build
        render("build_details.erb", binding)
      else
        render("never_built.erb", binding)
      end
    end
    
    def clean_out_working_files
      assert_private
      project_config_repository.clean_checkout_dir(project_name)
      build_details_redirect
    end
    
  protected
  
    attr_reader :report_classes
  
    def reports
      report_classes.collect {|c| c.new(selected_build, project_config_repository) }
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
    
    def extra_css
      selected_report.extra_css
    end

    def rss_url
      @rss_url + "?project_name=" + CGI.escape(project_name)
    end

    def tasks    
      result = super
      unless project_name.nil?
        if(private?)
          # Standard private operations
          result +=
            [
              task(:icon => "largeicons/box_into.png", :name => "Clone project", :url => "configure?project_name=#{project_name}&action=clone_project"),
              task(:icon => "largeicons/wrench.png", :name => "Configure", :url => "configure?project_name=#{project_name}&action=configure"),
              task(:icon => "largeicons/gears_run.png", :name => "Trig build now", :url => "?project_name=#{project_name}&action=trig_build"),
              task(:icon => "largeicons/garbage.png", :name => "Clean out working files", :url => "?project_name=#{project_name}&action=clean_out_working_files"),
            ]

          scm = project_config["scm"]

          # Create repo
          if(scm.can_create? && !scm.exists?)
            result +=
              [
                task(:icon => "largeicons/package_new.png", :name => "Create repository", :url => "configure?project_name=#{project_name}&action=create_scm")
              ]
          end
          # Install/uninstall trigger
          if(scm.exists?)
            trigger_command = DamageControl::XMLRPC::Trigger.trigger_command(damagecontrol_home, project_name, @trig_xmlrpc_url)
            trigger_files_checkout_dir = project_config_repository.trigger_checkout_dir(project_name)
            if(scm.supports_trigger? && scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
              result +=
                [
                  task(:icon => "largeicons/gear_delete.png", :name => "Uninstall trigger", :url => "install_trigger?project_name=#{project_name}&install=false"),
                ]
            elsif(scm.supports_trigger?)
              result +=
                [
                  task(:icon => "largeicons/gear_connection.png", :name => "Install trigger", :url => "install_trigger?project_name=#{project_name}&install=true"),
                ]
            end
          end

        end
        result +=
          [
            task(:icon => "largeicons/folders.png", :name => "Working files", :url => "root/#{project_name}/checkout"),
          ]
        prev_build = build_history_repository.prev(selected_build)
        if(prev_build)
          result +=
            [
              task(:icon => "largeicons/navigate_left.png", :name => "Previous build", :url => build_url(prev_build))
            ]
        end
        next_build = build_history_repository.next(selected_build)
        if(next_build)
          result +=
            [
              task(:icon => "largeicons/navigate_right.png", :name => "Next build", :url => build_url(next_build))
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
  
    def build_details_redirect
      action_redirect(:build_details, { "project_name" => project_name })
    end
    
    def selected_build
      dc_creation_time = request.query['dc_creation_time']
      if dc_creation_time then
        build_history_repository.lookup(project_name, request.query['dc_creation_time'])
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
