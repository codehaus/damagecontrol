require 'test/unit'

require 'pebbles/Process'

module Pebbles
  class ProcessTest < Test::Unit::TestCase
    def test_separate_stdout_and_stderr
      p = Pebbles::Process.new
      p.command_line = "echo stdout >&1 && echo stderr >&2"
      p.execute("echo stdout >&1 && echo stderr >&2") do |stdin, stdout, stderr|
        assert_equal("stdout\n", stdout.read)
        assert_equal("stderr\n", stderr.read)
      end
    end
    
    def test_stdout_and_stderr_with_stream_pumpers
      stdout_result = ""
      stderr_result = ""
      threads = []
      Pebbles::Process.new.execute("echo stdout >&1 && echo stderr >&2") do |stdin, stdout, stderr|
        threads << Thread.new do
          stdout_result += stdout.read
        end
        threads << Thread.new do
          stderr_result += stderr.read
        end
        threads.each{|t| t.join}
      end
      assert_equal("stdout\n", stdout_result)
      assert_equal("stderr\n", stderr_result)
    end
  end
end