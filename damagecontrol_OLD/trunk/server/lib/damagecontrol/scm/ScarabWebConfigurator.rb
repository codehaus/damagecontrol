require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'rubygems'
require 'rscm'

module DamageControl
  class ScarabWebConfigurator < AbstractTrackingConfigurator
  
  public
  
    def tracking_class
      RSCM::Tracker::Scarab
    end
    
    def tracking_display_name
      "Scarab"
    end
    
    def config_form_template
      "scarab_configure_form.erb"
    end
    
  protected
  
    def configuration_keys
      [
        "scarab_url",
        "scarab_module_key"
      ]
    end
  end
end