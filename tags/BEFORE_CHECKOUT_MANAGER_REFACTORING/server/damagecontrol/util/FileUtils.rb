require 'fileutils'
require 'ftools'
require 'damagecontrol/util/Logging'
require 'pebbles/Process'

module FileUtils

  include DamageControl::Logging

  def new_temp_dir(identifier = self)
    identifier = identifier.to_s
    identifier.gsub!(/\(|:|\)/, '_')
    dir = "#{damagecontrol_home}/target/temp_#{identifier}_#{Time.new.to_i}"
    mkdir_p(dir)
    dir
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

  def username
    ENV['USERNAME'] || ENV['USER']
  end
  
  def script_file(file)
    "#{file}.sh"
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
      File.mkpath(dir)
      p = Pebbles::Process.new
      p.command_line = cmd
      p.environment = environment
      p.working_dir = dir
      p.join_stdout_and_stderr = true
      ret = p.execute do |stdout, stdin|
        if proc.arity == 1 then proc.call(p.stdout) else proc.call(p.stdout, p.stdin) end
      end
      logger.debug("successfully executed #{cmd.inspect} in directory #{dir.inspect}")
      ret
    rescue NotImplementedError
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end

end
