require 'damagecontrol/scm/AbstractTrackingConfigurator'
require 'rubygems'
require_gem 'rscm'

module DamageControl
  class JiraWebConfigurator < AbstractTrackingConfigurator
  
  public
  
    def tracking_class
      RSCM::Tracker::JIRA
    end
    
    def tracking_display_name
      "Jira"
    end
    
    def config_form_template
      "jira_configure_form.erb"
    end
    
  protected
  
    def configuration_keys
      [
        "jira_url",
        "jira_project_id"
      ]
    end
  end
end
