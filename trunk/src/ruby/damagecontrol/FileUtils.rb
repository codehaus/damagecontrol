module DamageControl

  module FileUtils
  
    def windows?
      $:.each{ |line|
        if(line =~ /.*msvcrt.*/)
          return true
        end
      }
      false
    end
    
    def rmdir(dir)
      if windows?
        system("rmdir /S /Q #{dir}")
      else
        system("rm -Rf #{dir}")
      end
    end
    
    def damagecontrol_home
      $damagecontrol_home = find_damagecontrol_home if $damagecontrol_home.nil?
      $damagecontrol_home 
    end
    
    def find_damagecontrol_home(path='.')
      if File.exists?("#{path}/build.rb")
        File.expand_path(path)
      else
        find_damagecontrol_home("#{path}/..")
      end
    end
        
    # returns file relative target (used in build)
    def target_file(filename)
      damagecontrol_file("target/#{filename}")
    end
  end
end