require 'test/unit'
require 'ftools'
require 'damagecontrol/scm/CVS'

module DamageControl
	class CVSTest < Test::Unit::TestCase
		def setup
			@cvs = CVS.new
		end
		
		def test_parse_path_works_on_local_path
			cvsroot = ":local:/cvsroot/damagecontrol"
			mod = "damagecontrol"
			path = "#{cvsroot}:#{mod}"
			assert_equal([cvsroot, mod], @cvs.parse_path(path)[1,2])
		end
		
		def test_handles_pserver_path
			assert(@cvs.handles_path?(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"))
		end
		
		def test_does_not_handle_starteam_path
			assert(!@cvs.handles_path?("starteam://username:password@server/project/view/folder"))
		end
	end
end