require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class ConfigureProjectServlet < AbstractAdminServlet
    def initialize(project_config_repository, scm_configurator_classes)
      super(:private, nil, nil, project_config_repository)
      @scm_configurator_classes = scm_configurator_classes
    end
    
    def tasks
      result = []
      unless project_name.nil?
        if(private?)
          scm = project_config_repository.create_scm(project_name)
          if(scm.can_create? && !scm.exists?)
            result +=
              [
                task(:icon => "icons/package_new.png", :name => "Create repository", :url => "configure?project_name=#{project_name}&action=create_scm")
              ]
          end
          if(scm.can_install_trigger? && !scm.trigger_installed?(project_name))
            result +=
              [
                task(:icon => "icons/gear_connection.png", :name => "Install trigger", :url => "install_trigger?project_name=#{project_name}"),
              ]
          end
        end

        result += [
          task(:icon => "icons/navigate_left.png", :name => "Back to project", :url => "project?project_name=#{project_name}"),
        ]
      end 
      result
    end

    def default_action
      configure
    end
    
    def clone_project
      project_config = self.project_config
      action = "store_configuration"
      next_build_number = 1
      dependent_projects = from_array(project_config['dependent_projects'])
      logs_to_archive = from_array(project_config['logs_to_archive'])
      project_name = ""
      render("configure.erb", binding)
    end
    
    def configure
      action = "store_configuration"
      next_build_number = project_config_repository.peek_next_build_number(project_name)
      dependent_projects = from_array(project_config['dependent_projects'])
      logs_to_archive = from_array(project_config['logs_to_archive'])
      render("configure.erb", binding)
    end
        
    def store_configuration
      assert_private
      @project_config_repository.new_project(project_name) unless @project_config_repository.project_exists?(project_name)
      project_config = @project_config_repository.project_config(project_name)
      
      # copy the key/values from the request over to the project_config
      # request.each do |key, value| won't work - it takes too much.
      KEYS.each do |key|
        if (request.query[key])
          project_config[key] = request.query[key].to_s 
        else
          project_config[key] = nil
        end
      end
      project_config['dependent_projects'] = to_array(request.query['dependent_projects'])
      project_config['logs_to_archive'] = to_array(request.query['logs_to_archive'])
      scm_configurators(project_config).each do |scm_configurator|
        scm_configurator.store_configuration_from_request(request)
      end

      @project_config_repository.modify_project_config(project_name, project_config)
      @project_config_repository.set_next_build_number(project_name, request.query["next_build_number"].chomp.to_i) if request.query["next_build_number"]
      
      action_redirect(:configure, { "project_name" => project_name })
    end
    
    def create_scm
      scm = project_config_repository.create_scm(project_name)
      scm.create
      action_redirect(:configure, { "project_name" => project_name })
    end

  private
  
    KEYS = [
      "build_command_line", 
      "project_name", 
      "trigger", 
      "nag_email", 
      "jira_url", 
      "scm_type"
    ]
    
    def from_array(array)
      if array then array.join(', ') else nil end
    end
    
    def to_array(array)
      if array then array.split(",").collect{|e| e.strip} else [] end
    end
    
    def scm_configurators(project_config = project_config)
      @scm_configurator_classes.collect {|cls| cls.new(project_config, project_config_repository)}
    end
    
  end
end
