require 'fileutils'
require 'ftools'
require 'damagecontrol/util/Logging'

module Pebbles
  class Process
  
      attr_accessor :command_line
      attr_accessor :environment
      attr_accessor :working_dir
      attr_reader :pid
      attr_reader :exit_code
      
      def initialize
        @stdout_pipe = IO.pipe
        @stdin_pipe = IO.pipe
        
        @environment = {}
      end
    
      def stdout
        parent_read
      end
      
      def stdin
        parent_write
      end
    
      def execute
        @pid = fork do
          # in subprocess
          Dir.chdir(working_dir)
          environment.each {|key, val| ENV[key] = val}
          # both processes now have these open
          # it will not close entirely until both have closed them, which will make the child process hang
          # so we'll close these now in this process since we are not going to use them
          parent_read.close
          parent_write.close
          $stdin.reopen(child_read)
          $stdout.reopen(child_write)
          $stderr.reopen(child_write)
          exec(command_line)
        end
        # both processes now have these open
        # it will not close entirely until both have closed them, which will make the child process hang
        # so we'll close these now in this process since we are not going to use them
        child_read.close
        child_write.close
      end
      
      def wait
        ::Process::waitpid(pid)
        @exit_code = $?
      end
  
      private
      
        def parent_read
          @stdout_pipe[0]
        end
        
        def child_write
          @stdout_pipe[1]
        end
        
        def parent_write
          @stdin_pipe[0]
        end
        
        def child_read
          @stdin_pipe[1]
        end
        
  end
end

module FileUtils

  include DamageControl::Logging

  class ProcessFailedException < StandardError
  end
  
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
      File.mkpath(dir)
      p = Pebbles::Process.new
      p.command_line = cmd
      p.environment = environment
      p.working_dir = dir
      p.execute
      ret = if proc.arity == 1 then proc.call(p.stdout) else proc.call(p.stdout, p.stdin) end
      p.wait
      raise ProcessFailedException.new("'#{cmd}' in directory '#{Dir.pwd}' failed with code #{p.exit_code.to_s}") if $? != 0
      logger.debug("successfully executed #{cmd}")
      ret
    rescue NotImplementedError
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end

end
