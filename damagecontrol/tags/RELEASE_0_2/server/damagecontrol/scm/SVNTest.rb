require 'test/unit'
require 'damagecontrol/scm/GenericSCMTests'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/scm/Changes'

module DamageControl
  class SVNTest < Test::Unit::TestCase
  
    include GenericSCMTests

    def create_scm
      LocalSVN.new(new_temp_dir, "damagecontrolled")
    end

  end
end
