require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class InstallTriggerServlet < AbstractAdminServlet
    include FileUtils
    
    def initialize(project_config_repository, trig_xmlrpc_url)
      super(:private, nil, nil, project_config_repository)
      @trig_xmlrpc_url = trig_xmlrpc_url
    end
    
    def default_action
      install_trigger
    end
    
    def install_trigger
      trigger_installed = false
      damagecontrol_install_dir = damagecontrol_home
      scm = create_scm
      render("trigger_install.erb", binding)
    end
    
    def tasks
      task(:icon => "icons/navigate_left.png", :name => "Back to project", :url => "project?project_name=#{project_name}")
    end
    
    def do_install_trigger
      damagecontrol_install_dir = request.query['damagecontrol_install_dir']
      scm = create_scm
      error = nil
      begin
        if scm.trigger_installed?(project_name)
          logger.info("uninstalling triggers for #{project_name}")
          scm.uninstall_trigger(project_name)
        end
        logger.info("installing trigger for #{project_name}")
        scm.install_trigger(damagecontrol_install_dir, project_name, @trig_xmlrpc_url)
      rescue Exception => e
        error = e
      end
      render("trigger_installed.erb", binding)
    end
  end
end
