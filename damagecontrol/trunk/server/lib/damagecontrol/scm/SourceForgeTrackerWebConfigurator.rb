require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'rubygems'
require 'rscm'

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
        "sf_group_id",
        "sf_tracker_id"
      ]
    end
  end
end
