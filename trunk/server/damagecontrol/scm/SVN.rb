require 'ftools'
require 'damagecontrol/scm/AbstractSCM'

module DamageControl

  class SVN < AbstractSCM
    def initialize(config_map)
      super(config_map)
      @svnurl = config_map["svnurl"] || required_config_param("svnurl")
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
