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
  
  # Executes a command in a directory with the given environment.
  #
  # Can be used in the following way:
  #
  # a) cmd_with_io(...) { |stdout| ... }
  # b) cmd_with_io(...) { |stdin, stdout| ... }
  # c) cmd_with_io(...) { |stdin, stdout, stderr| ... }
  #
  # If option a) or b) is used, an internal thread will read (and discard)
  # stderr - to avoid that the stderr buffer fills up.
  #
  # If option c) is used, it is the caller's responsibility to read all streams,
  # typically in a separate thread for each.
  #
  def cmd_with_io_old(dir, cmd, environment = {}, &proc)
    begin
      File.mkpath(dir)
      p = Pebbles::Process.new
      p.command_line = cmd
      p.environment = environment
      p.working_dir = dir
      err_thread = nil
      ret = p.execute do |stdin, stdout, stderr|
        if(proc.arity == 3)
          proc.call(stdin, stdout, stderr)
        else
          # see http://jira.codehaus.org/browse/DC-312
          err_thread = Thread.new do
            begin
              logger.info("Reading (and discarding) stderr")
              logger.debug(stderr.read.chomp) unless stderr.closed?
              # This segfaults on Linux when the process is dead.
              # ./server/damagecontrol/util/FileUtils.rb:114: [BUG] Segmentation fault
              # ruby 1.8.2 (2004-11-06) [i686-linux]
            rescue
              # Some times we get a IOError: closed stream even if the stream is closed.
            end
          end
          if(proc.arity == 2)
            proc.call(stdin, stdout)
          else # 1
            proc.call(stdout)
          end
        end
      end
      err_thread.join if err_thread
      logger.debug("successfully executed #{cmd.inspect} in directory #{dir.inspect}")
      ret
    rescue NotImplementedError => e
      puts e.backtrace.join("\n")
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end
  
  def cmd_with_io(dir, cmd, stderr_file, environment, timeout, &proc)
    with_working_dir(dir) do
      stdout = nil
      ret = Pebbles::Process2.new(cmd, stderr_file, environment, timeout).execute do |stdout, process|
        proc.call(stdout, process)
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
