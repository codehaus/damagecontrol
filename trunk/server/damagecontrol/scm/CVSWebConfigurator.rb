require 'damagecontrol/scm/AbstractWebConfigurator'
require 'damagecontrol/scm/CVS'

module DamageControl
  class CVSWebConfigurator < AbstractWebConfigurator
    
  public

    def scm_class
      CVS
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
        "rsh_client"
      ]
    end
  end
end

