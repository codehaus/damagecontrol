#require 'win32/process'

module Pebbles

  at_exit do
    ObjectSpace.each_object(Pebbles::Process) do |p|
      p.kill if p.executing?
    end
  end

  class ProcessFailedException < StandardError
  end
  
  class Process
  
    attr_accessor :command_line
    attr_accessor :environment
    attr_accessor :working_dir
    attr_reader :pid
    attr_reader :exit_code

    def initialize
      @stdout_pipe = IO.pipe
      @stdin_pipe = IO.pipe
      @stderr_pipe = IO.pipe

      @environment = {}
    end

    def execute(cmd=nil)
      self.command_line = cmd if cmd
      ret = nil
      begin
        start
        ret = yield stdin, stdout, stderr
      ensure
        wait
      end
      raise ProcessFailedException.new(
        "\n\nThe command\n#{command_line}\nrun from directory\n#{working_dir}\nfailed with process return code\n#{exit_code.to_s}\n" +
        "Try to manually cd to the directory and run the command to diagnose further.\nAlso try to look up the documentation\n" +
        "for the failing process to find out what this error code might mean. Note: This is NOT an error code from DamageControl or Ruby, but\n" +
        "from a process that was launched by DamageControl.") if exit_code != 0
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

  private

    def start
      @pid = fork do
        # in subprocess
        Dir.chdir(working_dir) if working_dir
        environment.each {|key, val| ENV[key] = val}
        # both processes now have these open
        # it will not close entirely until both have closed them, which will make the child process hang
        # so we'll close these now in this process since we are not going to use them
        parent_stdout_read.close
        parent_stderr_read.close
        parent_write.close
        $stdin.reopen(child_read)
        $stdout.reopen(child_stdout_write)
        $stderr.reopen(child_stderr_write)
        exec(command_line)
      end
      @executing = true
      # both processes now have these open
      # it will not close entirely until both have closed them, which will make the child process hang
      # so we'll close these now in this process since we are not going to use them
      child_read.close
      child_stdout_write.close
      child_stderr_write.close
    end

    def close_all_streams
      stdin.close unless stdin.closed?
      stdout.close unless stdout.closed?
      stderr.close unless stderr.closed?
    end

    def stdin
      parent_write
    end

    def stdout
      parent_stdout_read
    end

    def stderr
      parent_stderr_read
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

