require 'damagecontrol/scm/AbstractWebConfigurator'
require 'rubygems'
require_gem 'rscm'

module DamageControl
  class SVNWebConfigurator < AbstractWebConfigurator
    
  public

    def scm_class
      RSCM::SVN
    end

    def scm_display_name
      "Subversion"
    end

    def javascript_on_load
      ""
    end

    def javascript_declarations_template
      nil
    end

    def config_form_template
      "svn_configure_form.erb"
    end

  protected

    def configuration_keys
      [
        "svnurl",
        "svnpath"
      ]
    end
      
  end
end

