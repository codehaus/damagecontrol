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
    return nil if url.nil?
    if(url && url[-1..-1] != "/")
      "#{url}/"
    else
      url
    end
  end
  
  def cmd_with_io(dir, cmd, environment = {}, &proc)
    begin
      parent_rd, child_wr = IO.pipe
      child_rd, parent_wr = IO.pipe
      logger.debug("executing #{cmd}")
      pid = fork do
        # in subprocess
        File.mkpath(dir)
        Dir.chdir(dir)
        environment.each {|key, val| ENV[key] = val}
        parent_rd.close
        parent_wr.close
        $stdin.reopen(child_rd)
        $stdout.reopen(child_wr)
        $stderr.reopen(child_wr)
        exec(cmd)
      end
      # in parent process
      child_wr.close
      child_rd.close
      ret = if proc.arity == 1 then proc.call(parent_rd) else proc.call(parent_rd, parent_wr) end
      parent_rd.close
      parent_wr.close
      Process::waitpid(pid)
      raise Exception.new("'#{cmd}' in directory '#{Dir.pwd}' failed with code #{$?.to_s}") if $? != 0
      logger.debug("successfully executed #{cmd}")
      ret
    rescue NotImplementedError
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end

end
