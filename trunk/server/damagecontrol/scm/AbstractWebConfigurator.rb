require 'pebbles/MVCServlet'

module DamageControl
  class AbstractWebConfigurator
    include Pebbles::SimpleERB
    
  public

    def initialize(project_config, project_config_repo)
      @project_config = project_config
      @project_config_repo = project_config_repo
    end

    def scm_id
      scm_class.name
    end

    def selected?
      project_config["scm"].is_a?(scm_class)
    end

    def store_configuration_from_request(request)
      # copy the key/values from the request over to the project_config
      # request.each do |key, value| won't work - it takes too much.
      project_config['scm'] = scm_class.new
      configuration_keys.each do |key|
        value = request.query[key].to_s.strip
        if (value && value != "")
          project_config['scm'].send("#{key}=", value)
        else
          project_config['scm'].send("#{key}=", nil)
        end
      end
    end
    
    def javascript_declarations
      erb(javascript_declarations_template, bind_keys(binding)) if javascript_declarations_template
    end
    
    def quote(text)
      return text unless text
      text.gsub(/\\/, "\\\\")
    end
    
    def bind_keys(binding)
      if(project_config['scm'].is_a?(scm_class))
        configuration_keys.each do |key|
          eval("#{key} = quote(project_config['scm'].#{key})", binding)
        end
      else
        configuration_keys.each do |key|
          eval("#{key} = ''", binding)
        end
      end
      binding
    end
    
    def config_form
      erb(config_form_template, bind_keys(binding))
    end

  protected

    attr_reader :project_config

    def template_dir
      File.expand_path(File.dirname(__FILE__))
    end
  end
end

