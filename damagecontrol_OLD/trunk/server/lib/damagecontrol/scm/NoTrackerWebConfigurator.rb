require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'damagecontrol/scm/NoTracker'

module DamageControl
  class NoTrackerWebConfigurator < AbstractTrackingConfigurator
    
    public
      
      def tracking_class
        NoTracker
      end
      
      def tracking_display_name
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

