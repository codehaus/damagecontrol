require 'fileutils'
require 'ftools'
require 'damagecontrol/util/Logging'
require 'pebbles/Process2'

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

  def new_temp_dir(identifier = self, parent=".")
    identifier = identifier.to_s
    identifier.gsub!(/\(|:|\)/, '_')
    dir = "#{damagecontrol_home}/target/#{parent}/temp_#{identifier}_#{Time.new.to_i}"
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
    
  def cmd_with_io(dir, cmd, stderr_file, environment, timeout, &proc)
    res = nil
    with_working_dir(dir) do
      ret = Pebbles::Process2.new(cmd, dir, stderr_file, environment, timeout).execute do |stdout, process|
        begin
          res = proc.call(stdout, process)
        ensure
          process.kill
        end
      end
      if(ret.nil?)
        return
      end
      if(ret != 0)
        msg = "\n" +
          "---------------------------------------\n" +
          "Process failed with return code #{ret}: #{cmd}\n" +
          "Dir: #{dir}\n" +
          "---------------------------------------\n" 
        raise ProcessFailedException.new(msg)
      end
    end
    res
  end
  
  # writes contents of a stream line by line to a file
  def write_to_file(input, file)
    mkdir_p(File.dirname(file))
    File.open(file, "w") do |f|
      input.each_line do |line|
        f.puts line
      end
    end
  end
  
  def windows?
    RUBY_PLATFORM == "i386-mswin32"
  end

  class ProcessFailedException < StandardError
  end

end
