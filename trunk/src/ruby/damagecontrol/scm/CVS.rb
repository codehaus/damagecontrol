require 'test/unit'
require 'damagecontrol/BuildBootstrapper'
require 'ftools'

module DamageControl

	# format of path is cvsroot:module
	# examples
	# :local:/cvsroot/damagecontrol:damagecontrol
	# :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol
	# if pserver is used, the user is assumed to already be authenticated with cvs login
	# prior to starting damagecontrol
	class CVS < SCM
		def handles_path?(path)
			parse_path(path)
		end
		
		def cvs(cmd)
			cmd = "cvs #{cmd}"
			puts "executing: #{cmd}"
			IO.popen(cmd) do |io|
				io.each_line do |progress|
					yield progress
				end
			end
		end
		
		def parse_path(path)
			/^(:.*:.*):(.*)$/.match(path)
		end
		
		def checkout(path, directory, &proc)
			directory.gsub!('/', '\\') # TODO won't work on linux
			cvsroot, mod = parse_path(path)[1,2]
			cvsroot.gsub!('/', '\\') # TODO won't work on linux
			File.mkpath(directory)
			Dir.chdir(File.dirname(directory))
			cvs("-d #{cvsroot} co -d #{File.basename(directory)} #{mod}", &proc)
		end
	end
	
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