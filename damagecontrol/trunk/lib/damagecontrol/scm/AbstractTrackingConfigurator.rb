require 'damagecontrol/scm/AbstractWebConfigurator'

module DamageControl
  class AbstractTrackingConfigurator < AbstractWebConfigurator
  
    public
      
      def tracking_id
        tracking_class.name
      end
  
      def selected?
        project_config["tracking"].is_a?(tracking_class)
      end
  
      def store_configuration_from_request(request)
        # copy the key/values from the request over to the project_config
        # request.each do |key, value| won't work - it takes too much.
        project_config['tracking'] = tracking_class.new
        configuration_keys.each do |key|
          value = request.query[key].to_s.strip
          if (value && value != "")
            project_config['tracking'].send("#{key}=", value)
          else
            project_config['tracking'].send("#{key}=", nil)
          end
        end
      end
      
      # TODO: Refactor. this is copy-paste from AbstractWebConfigurator
      def bind_keys(binding)
        if(project_config['tracking'].is_a?(tracking_class))
          configuration_keys.each do |key|
            eval("#{key} = quote(project_config['tracking'].#{key})", binding)
          end
        else
          configuration_keys.each do |key|
            eval("#{key} = ''", binding)
          end
        end
        binding
      end
  
  end
end
