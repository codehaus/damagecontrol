require 'damagecontrol/web/AbstractAdminServlet'

module DamageControl
  class ConfigureProjectServlet < AbstractAdminServlet
    def initialize(project_config_repository, scm_configurator_classes)
      super(:private, nil, nil, project_config_repository)
      @scm_configurator_classes = scm_configurator_classes
    end
    
    def tasks
      unless project_name.nil?
        task(:icon => "icons/navigate_left.png", :name => "Back to project", :url => "project?project_name=#{project_name}")
      end 
    end

    def default_action
      configure
    end
    
    def clone_project
      action = "store_configuration"
      project_config = self.project_config
      project_name = ""
      render("configure.erb", binding)
    end
    
    def configure
      action = "store_configuration"
      next_build_number = project_config_repository.peek_next_build_number(project_name)
      render("configure.erb", binding)
    end
        
    def store_configuration
      assert_private
      @project_config_repository.new_project(project_name) unless @project_config_repository.project_exists?(project_name)
      project_config = @project_config_repository.project_config(project_name)
      
      # copy the key/values from the request over to the project_config
      # request.each do |key, value| won't work - it takes too much.
      KEYS.each do |key|
        project_config[key] = request.query[key]
      end
      scm_configurators(project_config).each do |scm_configurator|
        scm_configurator.store_configuration_from_request(request)
      end

      @project_config_repository.modify_project_config(project_name, project_config)
      @project_config_repository.set_next_build_number(project_name, request.query["next_build_number"].chomp.to_i) if request.query["next_build_number"]
      
      action_redirect(:configure, { "project_name" => project_name })
    end
    
  private
  
    KEYS = [
      "build_command_line", 
      "project_name", 
      "unix_groups",
      "view_cvs_url",
      "trigger", 
      "nag_email", 
      "jira_url", 
      "scm_type"
    ]
    
    def scm_configurators(project_config = project_config)
      scm_configurator_classes.collect {|cls| cls.new(project_config)}
    end
    
    attr_reader :scm_configurator_classes
    
  end
end
