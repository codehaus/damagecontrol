require 'damagecontrol/scm/AbstractWebConfigurator'
require 'damagecontrol/scm/NoSCM'

module DamageControl
  class NoSCMWebConfigurator < AbstractWebConfigurator
    
    public
      
      def scm_class
        NoSCM
      end
      
      def scm_display_name
        "None"
      end
      
      def javascript_on_load
        ""
      end
      
      def javascript_declarations
        ""
      end
      
      def config_form
        ""
      end
      
    protected
    
      def configuration_keys
        []
      end
      
  end
end

