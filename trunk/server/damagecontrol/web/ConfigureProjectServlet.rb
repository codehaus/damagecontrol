require 'damagecontrol/util/FileUtils'
require 'damagecontrol/web/AbstractAdminServlet'
require 'damagecontrol/xmlrpc/Trigger'

module DamageControl
  class ConfigureProjectServlet < AbstractAdminServlet
    include FileUtils

    def initialize(project_config_repository, scm_configurator_classes, tracking_configurator_classes, trig_xmlrpc_url)
      super(:private, nil, nil, project_config_repository)
      @scm_configurator_classes = scm_configurator_classes
      @tracking_configurator_classes = tracking_configurator_classes
      @trig_xmlrpc_url = trig_xmlrpc_url
    end
    
    def tasks
      result = []
      unless project_name.nil?
        result += [
          task(:icon => "largeicons/navigate_left.png", :name => "Back to project", :url => "../project/#{project_name}"),
        ]
      end 
      result
    end

    def default_action
      configure
    end
    
    def clone_project
      configure_page("", project_config, 1)
    end
    
    def configure
      configure_page(project_name, project_config, project_config_repository.peek_next_build_number(project_name))
    end
        
    def store_configuration
      assert_private
      @project_config_repository.new_project(project_name) unless project_exists?
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
      project_config['logs_to_merge'] = to_array(request.query['logs_to_merge'])
      project_config['artifacts_to_archive'] = to_array(request.query['artifacts_to_archive'])
      project_config['polling'] = to_boolean(request.query['polling'])
      scm_configurators(project_config).find{|c| c.scm_id == request.query['scm_id'] }.store_configuration_from_request(request)

      tracking_configurators(project_config).find{|c| c.tracking_id == request.query['tracking_id'] }.store_configuration_from_request(request)

      @project_config_repository.modify_project_config(project_name, project_config)
      @project_config_repository.set_next_build_number(project_name, request.query["next_build_number"].chomp.to_i) if request.query["next_build_number"]
      
      action_redirect(:configure, { "project_name" => project_name })
    end
    
  private
  
    def configure_page(project_name, project_config, next_build_number)
      action = "store_configuration"
			# this is needed to have a fresh list of already checked dependencies
			@checked_projects = [ ]
			circular_dependency = find_cirular_dependencies(project_name, project_config['dependent_projects'])
      dependent_projects = from_array(project_config['dependent_projects'])
      logs_to_merge = from_array(project_config['logs_to_merge'])
      artifacts_to_archive = from_array(project_config['artifacts_to_archive'])
      fixed_build_time_hhmm = project_config['fixed_build_time_hhmm']
      render("configure.erb", binding)
    end
		
		def	find_cirular_dependencies(name, projects)
			project = ""
			puts "\n\n\n\n\n\nchecking #{name}"
			if @checked_projects
				puts "list of checked projects exists"
				@checked_projects << name
			else
				puts "making new list of checked projects"
				@checked_projects = [ name ]
			end
			if projects then
				#puts "there are dependent projects"
				projects.each { |project|
					#puts "one project is called #{project}"
					return "There are circular dependencies: Project <b>#{name}</b> depends on <b>#{project}</b>" if name == project
					if !@checked_projects.include?(project)
						subproject_config = project_config_repository.project_config(project)
						#puts "recursing to check project #{project}"
						sub_circular = find_cirular_dependencies(name, subproject_config['dependent_projects'])
						return sub_circular if sub_circular
					else
						#puts "project #{project} was already checked"
					end
				}
				return nil
			else
				return nil
			end
			rescue Exception => e
			return "The dependent project <b>#{project}</b> does not exist"
		end
  
    KEYS = [
      "build_command_line", 
      "trigger", 
      "nag_email", 
      "scm_web_url",
      "fixed_build_time_hhmm"
    ]
    
    def from_array(array)
      if array then array.join(', ') else nil end
    end
    
    def to_array(array)
      if array then array.split(",").collect{|e| e.strip} else [] end
    end
    
    def to_boolean(param)
      if param then true else false end
    end
    
    def scm_configurators(project_config = self.project_config)
      @scm_configurator_classes.collect {|cls|  cls.new(project_config, project_config_repository)  }
    end
    
    def tracking_configurators(project_config = self.project_config)
      @tracking_configurator_classes.collect {|cls| cls.new(project_config, project_config_repository)}
    end
  end
end
