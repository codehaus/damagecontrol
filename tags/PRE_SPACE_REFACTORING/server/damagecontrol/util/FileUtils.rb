require 'fileutils'
require 'ftools'
require 'damagecontrol/util/Logging'

module Pebbles
  class ProcessFailedException < StandardError
  end
  
  class Process
  
      attr_accessor :command_line
      attr_accessor :environment
      attr_accessor :working_dir
      attr_writer :join_stdout_and_stderr
      attr_reader :pid
      attr_reader :exit_code
      
      def initialize
        @stdout_pipe = IO.pipe
        @stdin_pipe = IO.pipe
        @stderr_pipe = IO.pipe
        
        @environment = {}
        @join_stdout_and_stderr = false
      end
    
      def stdout
        parent_stdout_read
      end
      
      def stderr
        parent_stderr_read
      end
      
      def stdin
        parent_write
      end
    
      def start
        raise "stderr stuff still does not work" unless join_stdout_and_stderr?
        @pid = fork do
          # in subprocess
          Dir.chdir(working_dir)
          environment.each {|key, val| ENV[key] = val}
          # both processes now have these open
          # it will not close entirely until both have closed them, which will make the child process hang
          # so we'll close these now in this process since we are not going to use them
          parent_stdout_read.close
          parent_stderr_read.close
          parent_write.close
          $stdin.reopen(child_read)
          $stdout.reopen(child_stdout_write)
          if join_stdout_and_stderr?
            $stderr.reopen(child_stdout_write) 
          else
            $stderr.reopen(child_stderr_write)
          end
          exec(command_line)
        end
        @executing = true
        # both processes now have these open
        # it will not close entirely until both have closed them, which will make the child process hang
        # so we'll close these now in this process since we are not going to use them
        child_read.close
        child_stdout_write.close
        child_stderr_write.close
        parent_stderr_read.close if join_stdout_and_stderr?
      end
      
      def execute
        ret = nil
        begin
          start
          if join_stdout_and_stderr?
            ret = yield stdin, stdout
          else
            ret = yield stdin, stdout, stderr
          end
          wait
        ensure
          close_all_streams
        end
        raise ProcessFailedException.new("'#{command_line}' in directory '#{working_dir}' failed with code #{exit_code.to_s}") if exit_code != 0
        ret
      end
      
      def executing?
        @executing
      end
      
      def kill
        ::Process.kill("KILL", pid)
      end
      
      def wait
        @pid, @exit_code = ::Process::waitpid2(pid)
        close_all_streams
        @executing = false
      end
      
      def close_all_streams
        stdin.close unless stdin.closed?
        stdout.close unless stdout.closed?
        stderr.close unless stderr.closed?
      end
  
      private
      
        def join_stdout_and_stderr?
          @join_stdout_and_stderr
        end
        
        def parent_stdout_read
          @stdout_pipe[0]
        end
        
        def child_stdout_write
          @stdout_pipe[1]
        end
        
        def parent_stderr_read
          @stderr_pipe[0]
        end
        
        def child_stderr_write
          @stderr_pipe[1]
        end
        
        def parent_write
          @stdin_pipe[1]
        end
        
        def child_read
          @stdin_pipe[0]
        end
        
  end
end

module FileUtils

  include DamageControl::Logging

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
      p.join_stdout_and_stderr = true
      ret = p.execute do |stdout, stdin|
        if proc.arity == 1 then proc.call(p.stdout) else proc.call(p.stdout, p.stdin) end
      end
      logger.debug("successfully executed #{cmd}")
      ret
    rescue NotImplementedError
      puts "DamageControl only runs in Cygwin on Windows"
      exit!
    end
  end

end
