require 'damagecontrol/scm/AbstractWebConfigurator'
require 'rubygems'
require 'rscm'

module DamageControl
  class StarTeamWebConfigurator < AbstractWebConfigurator
    
  public

    def scm_class
      RSCM::StarTeam
    end

    def scm_display_name
      "StarTeam"
    end

    def javascript_on_load
      ""
    end

    def javascript_declarations_template
      nil
    end

    def config_form_template
      "starteam_configure_form.erb"
    end

  protected

    def configuration_keys
      [
        "st_user_name", 
        "st_password", 
        "st_server_name", 
        "st_server_port", 
        "st_project_name", 
        "st_view_name", 
        "st_folder_name"
      ]
    end
      
  end
end

