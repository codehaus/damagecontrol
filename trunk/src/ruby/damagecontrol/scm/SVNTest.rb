require 'test/unit'
require 'ftools'
require 'damagecontrol/scm/SVN'

module DamageControl
  class SVNTest < Test::Unit::TestCase
    def setup
      @svn = SVN.new
    end
    
    def test_does_not_handle_pserver_spec
      assert(!@svn.handles_spec?(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"))
    end
    
    def test_does_not_handle_starteam_path
      assert(!@svn.handles_spec?("starteam://username:password@server/project/view/folder"))
    end
  end
end