require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'damagecontrol/scm/SourceForgeTracker'

module DamageControl
  class SourceForgeTrackerWebConfigurator < AbstractTrackingConfigurator
  
  public
  
    def tracking_class
      SourceForgeTracker
    end
    
    def tracking_display_name
      "SourceForge.net"
    end
    
    def config_form_template
      "sourceforge_configure_form.erb"
    end
    
  protected
  
    def configuration_keys
      [
        "group_id",
        "tracker_id"
      ]
    end
  end
end
