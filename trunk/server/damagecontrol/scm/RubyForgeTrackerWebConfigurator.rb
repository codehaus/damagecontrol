require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'damagecontrol/scm/RubyForgeTracker'

module DamageControl
  class RubyForgeTrackerWebConfigurator < AbstractTrackingConfigurator
  
  public
  
    def tracking_class
      RubyForgeTracker
    end
    
    def tracking_display_name
      "RubyForge.net"
    end
    
    def config_form_template
      "rubyforge_configure_form.erb"
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
