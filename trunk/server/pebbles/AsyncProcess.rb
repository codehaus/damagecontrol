require 'thread'
require 'timeout'

class ProcessError < SystemCallError
  attr_reader :message
  attr_reader :process_status

  def initialize(message, process_status)
    @message = message
    @process_status = process_status
  end
end

module Pebbles
  
  # Executes a process. This method returns as soon as the process has been
  # launched - before it finishes.
  #
  # A spearate thread is created, which will wait for the process to complete.
  # stdout can be read from this thread if stdout_proc is not nil.
  #
  # An additional thread will be created for each of stdin_proc and stderr_proc
  # If they are non nil.
  #
  # the waitfor method will block until the process finishes. It will raise an exception
  # if the process doesn't complete before the timeout - or if the process finishes
  # with a non-0 return code.
  #
  # The reason why all threads are managed internally is to be able to shut them down properly
  #
  class AsyncProcess
    include FileTest

    def initialize(dir, cmd, stdin_proc, stdout_proc, stderr_proc, environment, timeout)
      @executing = true
      @mutex = Mutex.new

      @threads = []
    
      @stdin_pipe = IO::pipe
      @stdout_pipe = IO::pipe
      @stderr_pipe = IO::pipe

      @pid = fork do
        environment.each { |key, val| ENV[key] = val } if environment
        @stdin_pipe[1].close
        STDIN.reopen(@stdin_pipe[0])
        @stdin_pipe[0].close

        @stdout_pipe[0].close
        STDOUT.reopen(@stdout_pipe[1])
        @stdout_pipe[1].close

        @stderr_pipe[0].close
        STDERR.reopen(@stderr_pipe[1])
        @stderr_pipe[1].close

        current_dir = Dir.pwd
        begin
          if dir
            raise "No such directory: #{dir}" unless exist?(dir)
            Dir.chdir(dir) 
          end
          exec(cmd)
        rescue Errno::ENOENT
          raise SystemCallError.new("Command not found:\n#{cmd}\n")
        ensure
          Dir.chdir(current_dir)
        end
      end

      @stdin_pipe[0].close
      @stdout_pipe[1].close
      @stderr_pipe[1].close

      # Need to sync here so this method returns only after the thread has started
      init = ConditionVariable.new
      
      @mutex.synchronize do
        @t = Thread.new do
          timeout(timeout) do
            begin
              @threads << stdout_thread = Thread.new { stdout_proc.call(@stdout_pipe[0]) } if stdout_proc
              @threads << stdin_thread = Thread.new { stdin_proc.call(@stdin_pipe[1]) } if stdin_proc
              @threads << stderr_thread = Thread.new { stderr_proc.call(@stderr_pipe[0]) } if stderr_proc

              # It's ok to return now that the thread has started
              init.signal
              # FixNum, Process::ProcessStatus
              pid, process_status = Process.waitpid2(@pid)
              if(process_status.exitstatus != 0)
                # read the rest of the output
                raise ProcessError.new("Process failed:\n#{cmd}\nExit code: #{process_status}", process_status)
              end
            rescue Timeout::Error => e
              kill
              raise e
            ensure
              @threads.each { |thread| thread.join }
              @stdin_pipe[1].close unless @stdin_pipe[1].closed?
              @stdout_pipe[0].close unless @stdout_pipe[1].closed?
              @stderr_pipe[0].close unless @stderr_pipe[1].closed?
              @executing = false
            end
          end
        end
      end
      
      @mutex.synchronize do
        init.wait(@mutex)
      end
    end
    
    def waitfor
      @t.join
    end
    
    def executing?
      @executing
    end
    
    def kill
      Process.kill("SIGHUP", @pid)
      @threads.each { |thread| thread.kill }
      @stdin_pipe[1].close unless @stdin_pipe[1].closed?
      @stdout_pipe[0].close unless @stdout_pipe[1].closed?
      @stderr_pipe[0].close unless @stderr_pipe[1].closed?
    end
    
  end
  
end  

if $0 == __FILE__

require 'test/unit'
require 'pebbles/mockit'

class AsyncProcessTest < Test::Unit::TestCase
  include MockIt
  
  def test_should_return_zero_for_successful_command
    out = new_mock.__expect(:stdout) {|out| assert_equal("BAR\n", out)}
    p = Pebbles::AsyncProcess.new(
      ".",
      "echo $FOO",
      nil,
      Proc.new{|io| out.stdout(io.read)},
      nil,
      {"FOO" => "BAR"},
      2
    )
    p.waitfor
  end

  def test_should_throw_exception_for_nonexisting_command
    p = Pebbles::AsyncProcess.new(
      ".",
      "jalla",
      nil,
      nil,
      nil,
      nil,
      2
    )
    assert_raises(ProcessError) do
      p.waitfor
    end
  end

  def test_should_time_out_and_return_non_zero_for_long_running_command
    p = Pebbles::AsyncProcess.new(
      ".",
      "cat",
      nil,
      nil,
      nil,
      nil,
      1
    )
    assert_raises(TimeoutError) do
      p.waitfor
    end
  end

  def test_should_time_out_and_return_non_zero_for_long_running_command2
    p = Pebbles::AsyncProcess.new(
      ".",
      "cat",
      nil,
      Proc.new{|io| puts(io.read)},
      Proc.new{|io| puts(io.read)},
      nil,
      1
    )
    assert_raises(TimeoutError) do
      p.waitfor
    end
  end

  def test_should_fail_if_one_command_is_bad
    p = Pebbles::AsyncProcess.new(
      ".",
      "ls; jalla",
      nil,
      nil,
      nil,
      nil,
      1
    )
    assert_raises(ProcessError) do
      p.waitfor
    end
  end

  def test_should_fail_if_command_fails
    err = new_mock.__expect(:stderr) {|err| assert_equal("ln: missing file argument\nTry `ln --help' for more information.\n", err)}
    p = Pebbles::AsyncProcess.new(
      ".",
      "ln",
      nil,
      nil,
      Proc.new{|io| err.stderr(io.read)},
      nil,
      1
    )
    assert_raises(ProcessError) do
      p.waitfor
    end
  end
end


end
