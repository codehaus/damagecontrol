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
    require 'rbconfig.rb'
    !Config::CONFIG["host"].index("mswin32").nil?
  end
    
  def username
    ENV['USERNAME'] || ENV['USER']
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
  
  def ensure_trailing_slash(url)
    if(url && url[-1..-1] != "/")
      "#{url}/"
    else
      url
    end
  end
  
  def cmd_with_io(dir, cmd, &proc)
    begin
      parent, child = IO.pipe
      pid = fork
      logger.debug("executing #{cmd}")
      if pid
        # in parent process
        child.close
        ret = yield parent
        parent.close
        Process::waitpid(pid)
        raise Exception.new("'#{cmd}' in directory '#{Dir.pwd}' failed with code #{$?.to_s}") if $? != 0
        logger.debug("successfully executed #{cmd}")
        ret
      else
        # in subprocess
        File.mkpath(dir)
        Dir.chdir(dir)
        parent.close
        $stdin.reopen(child)
        $stdout.reopen(child)
        $stderr.reopen(child)
        exec(cmd)
      end
    rescue NotImplementedError
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end

end
