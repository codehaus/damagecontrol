require 'ftools'

module DamageControl

  class SVN
  
    def initialize(svnurl, working_dir_root)
      @svnurl = svnurl
    end
  
    def checkout(directory, &proc)
      sleep 1
      File.mkpath(directory)
      with_working_dir(File.dirname(directory)) do
        svn("checkout #{@svnurl}", &proc)
      end
    end

  private

    def svn(cmd)
      cmd = "svn #{cmd}"
      puts "SVN executing: #{cmd}"
      IO.popen(cmd) do |io|
        io.each_line do |progress|
          yield progress
        end
      end    
    end
    
  end
end
