require 'pebbles/MVCServlet'

module DamageControl
  class AbstractWebConfigurator
    include Pebbles::SimpleERB
    
    public
    
      def initialize(project_config)
        @project_config = project_config
      end
      
      def scm_id
        scm_class.name
      end
      
      def selected?
        project_config["scm_type"] == scm_class.name
      end
      
      def store_configuration_from_request(request)
        # copy the key/values from the request over to the project_config
        # request.each do |key, value| won't work - it takes too much.
        configuration_keys.each do |key|
          project_config[key] = request.query[key]
        end
      end
      
    protected
      
      attr_reader :project_config
      
      def template_dir
        File.expand_path(File.dirname(__FILE__))
      end
  end
end
