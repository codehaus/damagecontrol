require 'fileutils'
require 'ftools'

module FileUtils

  def new_temp_dir(identifier = self)
    identifier = identifier.to_s
    identifier.gsub!(/\(|:|\)/, '_')
    "#{damagecontrol_home}/target/temp_#{identifier}_#{Time.new.to_i}"
  end
  
  def with_working_dir(dir)
    prev = Dir.pwd
    begin
      File.mkpath(dir)
      Dir.chdir(dir)
      yield
    ensure
      Dir.chdir(prev)
    end
  end

  def windows?
    $:.each{ |line|
      if(line =~ /.*msvcrt.*/)
        return true
      end
    }
    false
  end
    
  def username
    return ENV["USERNAME"] if windows?
    ENV["USER"]
  end
  
  def script_file(file)
    return "#{file}.bat" if windows?
    "#{file}.sh"
  end
  
  def path_separator
    windows? ? "\\" : "/"
  end
    
  def to_os_path(path)
    path.gsub('/', path_separator)
  end
    
  def damagecontrol_home
    $damagecontrol_home = find_damagecontrol_home.untaint if $damagecontrol_home.nil?
    $damagecontrol_home
  end
    
  def find_damagecontrol_home(path='.')
    if File.exists?("#{path}/build.rb")
      File.expand_path(path)
    else
      find_damagecontrol_home("#{path}/..")
    end
  end
  
end
