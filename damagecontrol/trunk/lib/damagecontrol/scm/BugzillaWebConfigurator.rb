require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'rubygems'
require_gem 'rscm'

module DamageControl
  class BugzillaWebConfigurator < AbstractTrackingConfigurator
  
  public
  
    def tracking_class
      Bugzilla
    end
    
    def tracking_display_name
      "Bugzilla"
    end
    
    def config_form_template
      "bugzilla_configure_form.erb"
    end
    
  protected
  
    def configuration_keys
      [
        "bugzilla_url"
      ]
    end
  end
end
