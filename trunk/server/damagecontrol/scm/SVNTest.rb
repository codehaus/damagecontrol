require 'test/unit'
require 'ftools'
require 'damagecontrol/scm/AbstractSCMTest'
require 'damagecontrol/scm/SVN'
require 'webrick'

module DamageControl
  class SVNTest < AbstractSCMTest

    def create_scm
      LocalSVN.new(new_temp_dir, "damagecontrolled")
    end
  end
end
