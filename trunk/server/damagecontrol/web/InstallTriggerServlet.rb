require 'damagecontrol/util/FileUtils'
require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/xmlrpc/Trigger'

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
      install = request.query['install'] == "true"
      trigger_installed = false
      damagecontrol_install_dir = damagecontrol_home
      scm = @project_config_repository.create_scm(project_name)
      render("trigger_install.erb", binding)
    end
    
    def tasks
      task(:icon => "largeicons/navigate_left.png", :name => "Back to project", :url => "../project/#{project_name}")
    end
    
    def do_install_trigger
      damagecontrol_install_dir = request.query['damagecontrol_install_dir']
      scm = @project_config_repository.create_scm(project_name)
      error = nil
      trigger_command = DamageControl::XMLRPC::Trigger.trigger_command(damagecontrol_install_dir, project_name, @trig_xmlrpc_url)
      trigger_files_checkout_dir = project_config_repository.trigger_checkout_dir(project_name)
      begin
        if scm.trigger_installed?(trigger_command, trigger_files_checkout_dir)
          logger.info("uninstalling trigger for #{project_name}")
          scm.uninstall_trigger(trigger_command, trigger_files_checkout_dir)
        end
        logger.info("installing trigger for #{project_name}")
        scm.install_trigger(trigger_command, trigger_files_checkout_dir)
      rescue Exception => e
        error = e
      end
      render("trigger_installed.erb", binding)
    end

    def do_uninstall_trigger
      damagecontrol_install_dir = request.query['damagecontrol_install_dir']
      scm = create_scm
      error = nil
      trigger_command = DamageControl::XMLRPC::Trigger.trigger_command(damagecontrol_install_dir, project_name, @trig_xmlrpc_url)
      trigger_files_checkout_dir = project_config_repository.trigger_checkout_dir(project_name)
      begin
        if !scm.trigger_installed?(trigger_command, trigger_files_checkout_dir)
          raise "Trigger command isn't installed: '#{trigger_command}'"
        else
          logger.info("uninstalling trigger for #{project_name}")
          scm.uninstall_trigger(trigger_command, trigger_files_checkout_dir)
        end
        if scm.trigger_installed?(trigger_command, trigger_files_checkout_dir)
          raise "Trigger command wasn't successfully uninstalled: '#{trigger_command}'"
        end
      rescue Exception => e
        error = e
      end
      render("trigger_uninstalled.erb", binding)
    end

  end
end
