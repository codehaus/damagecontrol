require 'damagecontrol/scm/AbstractWebConfigurator'

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
      
      def javascript_declarations
        erb("cvs_declarations.js", binding)
      end
      
      def config_form
        erb("cvs_configure_form.erb", binding)
      end
      
    protected
    
      def configuration_keys
        [
          "cvsroot", 
          "cvsmodule", 
          "cvspassword", 
          "cvs_web_url"
        ]
      end
      
  end
end

