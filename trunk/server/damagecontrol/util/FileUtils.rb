require 'fileutils'
require 'ftools'
require 'damagecontrol/util/Logging'

module FileUtils

  include DamageControl::Logging

  def all_files_recursively(dir)
    if File.directory?(dir)
      entries = Dir["#{dir}/*"]
      entries.collect {|entry| all_files_recursively(entry)}.flatten
    else
      dir
    end
  end
  
  def all_files(src)
    src = File.expand_path(src)
    src_length = src.size + 1
    files = all_files_recursively(src).collect {|f| File.expand_path(f)[src_length..-1]}
    files.delete_if {|f| f =~ /CVS\//}
    files.delete_if {|f| f=~ /^\.#/}
  end
  
  def copy_dir(src, dest)
    files = all_files(src)
    files.each do |file|
      file_dest = "#{dest}/#{File.dirname(file)}"
      mkdir_p(file_dest)
      cp("#{src}/#{file}", file_dest)
    end
  end

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
			p.join_stdout_and_stderr = false unless proc.arity == 1
      p.join_stdout_and_stderr = true if proc.arity == 1
      ret = p.execute do |stdout, stdin|
        if proc.arity == 1 then proc.call(p.stdout) else proc.call(p.stdout, p.stdin) end
      end
      logger.debug("successfully executed #{cmd.inspect} in directory #{dir.inspect}")
      ret
    rescue NotImplementedError => e
      puts e.backtrace.join("\n")
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end
  
  def windows?
    ENV['WINDIR'] || ENV['windir']
  end

end
