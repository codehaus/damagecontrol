require 'test/unit'

require 'damagecontrol/CVSPoller'

class CVSPollerTest < Test::Unit::TestCase
	def setup
		lastmodifiedtime = Time.now
		@cvsroot = File.expand_path("#{targetdir()}/cvsroot#{Time.now.to_i}")
		Dir::mkdir(@cvsroot) unless FileTest::exist?(@cvsroot)
		@cvsroot = "" + @cvsroot
		system("cvs -d :local:#{@cvsroot} init")
		@poller = CVSPoller.new
		@poller.cvsroot = ":local:" + @cvsroot
		@poller.cvsmodule = "CVSROOT"
		@poller.last_buildtime = lastmodifiedtime - 10
	end
	
	def teardown
		begin
			delete(@cvsroot)
		rescue
		end
	end
	
	def delete (dir)
		if FileTest::directory?(dir)
			Dir::foreach(dir) {|sub|
				delete(dir + File::SEPARATOR + sub) unless sub == "." || sub == ".."
			}
			Dir::rmdir(dir)
		else
			File::delete(dir)
		end
	end
	
	def targetdir
		basedir = "../.."
		targetdir = "#{basedir}/target"
		Dir::mkdir(targetdir) unless FileTest::exist?(targetdir)
		targetdir
	end
	
	def test_was_modified
		assert(!@poller.wasmodified(@poller.last_buildtime + 5))
		assert(@poller.wasmodified(Time.now))
	end
end

