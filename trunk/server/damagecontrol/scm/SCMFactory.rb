require 'damagecontrol/scm/CVS'
require 'damagecontrol/scm/SVN'

module DamageControl
  class SCMFactory
    def get_scm(config_map, checkout_dir_root)
      case config_map["scm_type"]
        when "cvs"
          CVS.new(config_map["cvsroot"], config_map["cvsmodule"], checkout_dir_root)
        when "svn"
          SVN.new(config_map["svnurl"], checkout_dir_root)
      end
    end
  end
end
