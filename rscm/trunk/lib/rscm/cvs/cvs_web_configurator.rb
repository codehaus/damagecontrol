#require 'damagecontrol/scm/AbstractWebConfigurator'

module RSCM
  class CVSWebConfigurator #< AbstractWebConfigurator
    
    def scm_class
      CVS
    end

    def javascript_on_load
      "distributeCvsrootFields()"
    end

    def javascript
      File.dirname(__FILE__) + "/cvs_declarations.js"
    end

    def config_form_template
      "cvs_configure_form.rhtml"
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

