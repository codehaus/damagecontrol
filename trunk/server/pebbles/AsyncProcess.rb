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
  def execute(cmd, dir=".", environment={})

    stdin_pipe = IO::pipe
    stdout_pipe = IO::pipe
    stderr_pipe = IO::pipe

    pid = fork do
      environment.each { |key, val| ENV[key] = val } if environment
      stdin_pipe[1].close
      STDIN.reopen(stdin_pipe[0])
      stdin_pipe[0].close

      stdout_pipe[0].close
      STDOUT.reopen(stdout_pipe[1])
      stdout_pipe[1].close

      stderr_pipe[0].close
      STDERR.reopen(stderr_pipe[1])
      stderr_pipe[1].close

      current_dir = Dir.pwd
      begin
        if dir
          raise "No such directory: #{dir}" unless File.exist?(dir)
          Dir.chdir(dir) 
        end
        exec(cmd)
      rescue Errno::ENOENT
        raise SystemCallError.new("Command not found:\n#{cmd}\n")
      ensure
        Dir.chdir(current_dir)
      end
    end

    stdin_pipe[0].close
    stdout_pipe[1].close
    stderr_pipe[1].close

    begin
      # FixNum, Process::ProcessStatus
puts "YIELDING streams"
      yield stdin_pipe[1], stdout_pipe[0], stderr_pipe[0], pid if block_given?
puts "YIELDED streams - WAITING for process"
      pid, process_status = Process.waitpid2(pid)
puts "Process done: #{pid} #{process_status}"
      if(process_status.exitstatus != 0)
        # read the rest of the output
        raise ProcessError.new("Process failed:\n#{cmd}\nExit code: #{process_status}", process_status)
      end
putd "RETURNING FROM EXEC"
      return process_status.exitstatus
    rescue Timeout::Error => e
      Process.kill("SIGHUP", pid)
      raise e
    ensure
putd "CLOSING STREAMS"
      stdin_pipe[1].close unless stdin_pipe[1].closed?
      stdout_pipe[0].close unless stdout_pipe[0].closed?
      stderr_pipe[0].close unless stderr_pipe[0].closed?
    end
    module_function :execute
  end
     
end  

if $0 == __FILE__

  require 'test/unit'
  require 'pebbles/mockit'

  class AsyncProcessTest < Test::Unit::TestCase
    include MockIt
    include Pebbles

    def test_should_return_zero_for_successful_command
      ret = execute("echo $FOO", ".", {"FOO" => "BAR"}) do |stdin, stdout, stderr, pid|
        assert_equal("BAR\n", stdout.read)
      end
      assert_equal(0, ret)
    end

    def test_should_read_nothing_and_throw_exception_for_nonexisting_command
      m = new_mock.__expect(:out) {|o| assert_equal("", o)}
      assert_raises(ProcessError) do
        execute("jalla") do |stdin, stdout, stderr|
          m.out(stdout.read)
        end
      end
    end

    def test_should_read_something_and_throw_exception_for_nonexisting_second_command
      out = new_mock.__expect(:print) {|o| 
        assert_equal("CVS\ncl\ndamagecontrol\ngplot\njabber4r\nlog4r\nlog4r.rb\nnqxml\nopen4.rb\npebbles\nrexml\nrica\nxmlrpc\n", o)
      }
      err = new_mock.__expect(:print) {|o| 
        assert_equal("jalla: not found\n", o)
      }
      assert_raises(ProcessError) do
        execute("ls server; jalla") do |stdin, stdout, stderr, pid|
          out.print(stdout.read)
          err.print(stderr.read)
        end
      end
    end

    def test_should_suicicde_on_timeout
      pid = nil
      begin
        timeout(1) do
          execute("cat") do |stdin, stdout, stderr, pid|
            # This will block too
            stdout.read
          end
        end
        flunk
      rescue TimeoutError => expected
        begin
          Process.kill("SIGHUP", pid)
          flunk
        rescue Errno::EPERM => expected
          # process should already be killed
        end
      end
    end

    def test_should_be_able_to_kill_long_running_command
      timeout(2) do
        begin
          execute("cat") do |stdin, stdout, stderr, pid|
            sleep(1)
            Process.kill("SIGHUP", pid)
          end
        rescue ProcessError => expected
          assert_equal(nil, expected.process_status.exitstatus)
        end
      end
    end

    def test_should_fail_if_command_fails
      m = new_mock.__expect(:out) {|o| 
        assert_equal("ln: missing file argument\nTry `ln --help' for more information.\n", o)
      }
      begin
        execute("ln") do |stdin, stdout, stderr, pid|
          o = stderr.read
          m.out(o)
        end
        flunk
      rescue ProcessError => expected
        assert_equal(1, expected.process_status.exitstatus)
      end
    end
  end

end
