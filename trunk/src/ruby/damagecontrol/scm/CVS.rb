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
                        puts "cvs handles path: #{path}"
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
end