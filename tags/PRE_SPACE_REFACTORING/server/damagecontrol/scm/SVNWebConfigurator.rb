require 'damagecontrol/scm/AbstractWebConfigurator'
require 'damagecontrol/scm/SVN'

module DamageControl
  class SVNWebConfigurator < AbstractWebConfigurator
    
    public
      
      def scm_class
        SVN
      end
      
      def scm_display_name
        "Subversion"
      end
      
      def javascript_on_load
        ""
      end
      
      def javascript_declarations
        ""
      end
      
      def config_form
        erb("svn_configure_form.erb", binding)
      end
      
    protected
    
      def configuration_keys
        [
          "svnurl",
          "svnprefix",
          "svn_web_url"
        ]
      end
      
  end
end

