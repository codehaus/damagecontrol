require 'damagecontrol/scm/AbstractWebConfigurator'
require 'rubygems'
require_gem 'rscm'

module DamageControl
  class CVSWebConfigurator < AbstractWebConfigurator
    
  public

    def scm_class
      RSCM::CVS
    end

    def scm_display_name
      "CVS"
    end

    def javascript_on_load
      "distributeCvsrootFields()"
    end

    def javascript_declarations_template
      "cvs_declarations.js"
    end

    def config_form_template
      "cvs_configure_form.erb"
    end

  protected

    def configuration_keys
      [
        "cvsroot", 
        "cvsmodule", 
        "cvspassword",
        "cvsbranch"
      ]
    end
  end
end

