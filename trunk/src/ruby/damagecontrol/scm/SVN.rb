require 'ftools'
require 'damagecontrol/scm/SCM'

module DamageControl

    class SVN < SCM
    
        def handles_path?(path)
            print "svn handles path: #{path}"
            if(/^(.+)\:\/\//.match(path)) then
                method = $1
                return method == "svn" || method == "http" || method == "file"
            end
            return false
        end
        
        def svn(cmd)
            cmd = "svn #{cmd}"
            puts "executing: #{cmd}"
            IO.popen(cmd) do |io|
                io.each_line do |progress|
                    yield progress
                end
            end        
        end
        
        def checkout(path, directory, &proc)
            File.mkpath(directory)
            Dir.chdir(File.dirname(directory))
            svn("checkout #{path}", &proc)
        end
        
    end
end
