require 'ftools'
require 'damagecontrol/scm/SCM'

module DamageControl

    class SVN < SCM
    
        def handles_spec?(spec)
            if(/^(.+)\:\/\//.match(spec)) then
                method = $1
                return method == "svn" || method == "http" || method == "file"
            end
            return false
        end
        
        def svn(cmd)
            cmd = "svn #{cmd}"
            puts "SVN executing: #{cmd}"
            IO.popen(cmd) do |io|
                io.each_line do |progress|
                    yield progress
                end
            end        
        end
        
        def checkout(spec, directory, &proc)
            sleep 1
            File.mkpath(directory)
            with_working_dir(File.dirname(directory)) do
              svn("checkout #{spec}", &proc)
            end
        end
        
    end
end
