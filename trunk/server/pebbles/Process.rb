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

