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
  
    def path_separator
      windows? ? '\\' : '/'
    end
  
    def is_special_filename(filename)
      filename == '.' || filename == '..'
    end
    
    def delete(item)
      delete_directory(item) if FileTest::directory?(item) && !is_special_filename(item)
      File.rm_f(item) if FileTest::file?(item)
    end
    
    def delete_directory(dir)
      Dir.foreach(dir) do |file|  delete_file_in_dir(dir, file) end
      File.rm_f(dir)
    end
    
    def delete_file_in_dir(dir, filename)
      delete("#{dir}/#{filename}") unless is_special_filename(filename)
    end

    alias :rmdir :delete

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
    
    # returns file relative damagecontrol-home
    def damagecontrol_file(filename)
      "#{damagecontrol_home}/#{filename}"
    end

    # returns file relative target (used in build)
    def target_file(filename)
      damagecontrol_file("target/#{filename}")
    end
  end
end