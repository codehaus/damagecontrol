require 'test/unit'
require 'timeout'
require 'pebbles/Process2'

module Pebbles   

  class Process2Test < Test::Unit::TestCase 
    
    def blocking_command
      RUBY_PLATFORM == "i386-mswin32" ? "notepad" : "cat"
    end

    def Xtest_should_return_one_for_failing_command
      assert_equal(1, Process2.new("cvs mooky").execute)
    end

    def Xtest_should_return_127_for_unknown_command_with_redirected_stderr
      assert_equal(127, Process2.new("mooky", "stderr.log").execute)
    end

    def Xtest_should_return_1_for_unknown_command_without_redirected_stderr
      assert_equal(1, Process2.new("mooky").execute)
    end

    def Xtest_should_return_zero_for_successful_command_and_yield_stdout
      ret = Process2.new("cvs --version").execute do |stdout, process|
        assert_match(/CVSNT version/, stdout.read)
      end
      assert_equal(0, ret)
    end

    def Xtest_should_be_able_to_kill_explicitly
      ret = Process2.new(blocking_command).execute do |stdout, process|
        process.kill
      end
      assert_equal(nil, ret)
    end
    
    def Xtest_should_kill_on_timeout_and_return_nil_exit_code
      timeout(3) do
        ret = Process2.new(blocking_command, nil, {}, 2).execute do |stdout, process|
          #puts stdout.read
        end
        assert_nil(ret)
      end
    end

    def test_should_allow_killing_in_different_thread_while_reading
      process = nil
      read_interrupted = false
      execute_thread = Thread.new do
        ret = Process2.new(blocking_command).execute do |stdout, process|
          stdout.read
          read_interrupted = true
        end
      end
      sleep(1)
      process.kill
      execute_thread.join
      assert(read_interrupted)
    end
    
    def test_should_allow_killing_in_different_thread_while_reading_and_writing_to_file
      process = nil
      read_interrupted = false
      execute_thread = Thread.new do
        ret = Process2.new(blocking_command).execute do |stdout, process|
          file = "tmp.txt"
          File.open(file, "w") do |f|
            stdout.each_line do |line|
              f.puts line
            end
          end
          read_interrupted = true
        end
      end
      sleep(1)
      process.kill
      execute_thread.join
      assert(read_interrupted)
    end
    
    def Xtest_should_allow_status_query_from_different_thread
      process = nil
      execute_thread = Thread.new do
        ret = Process2.new(blocking_command).execute do |stdout, process|
        end
      end
      sleep(1)
      assert(!process.killed?)
      assert(process.running?)
      process.kill
      assert(!process.running?)
      assert(process.killed?)
      execute_thread.join
    end
    
    def Xtest_should_allow_different_environment_in_parallel_processes
      threads = []
      mooky_env = RUBY_PLATFORM == "i386-mswin32" ? "%MOOKY%" : "$MOOKY"
      (1..5).each do |n|
        threads << Thread.new do
          Process2.new("echo mooky is #{mooky_env}", nil, {"MOOKY" => "#{n}"}, 6).execute do |stdout, process|
            t = rand(5)
            puts "#{n} sleeping #{t}"
            sleep(t)
            assert_match(/mooky is #{n}/, stdout.read)
          end
          puts "exit #{n}"
        end
      end
      
      threads.each {|t| t.join}
    end

    def Xtest_should_compute_winprocess_difference
      before = [Win32Process.new(3, "three"), Win32Process.new(1, "one"), Win32Process.new(2, "two")]
      after = [Win32Process.new(3, "three"), Win32Process.new(1, "one"), Win32Process.new(4, "four"), Win32Process.new(2, "two")]
      diff = after - before
      assert_equal(1, diff.size)
      assert_equal(Win32Process.new(4, "four"), diff[0])
    end

  end  
end