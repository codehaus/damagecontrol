require 'test/unit'

require 'pebbles/Process'

module Pebbles
  class ProcessTest < Test::Unit::TestCase
    def test_joined_stdout_and_stderr
      p = Pebbles::Process.new
      p.command_line = "echo stdout >&1 && echo stderr >&2"
      p.join_stdout_and_stderr = true
      p.start
      assert_equal("stdout\nstderr\n", p.stdout.read)
      p.wait
    end
    
    def test_separate_stdout_and_stderr
      p = Pebbles::Process.new
      p.command_line = "echo stdout >&1 && echo stderr >&2"
      p.join_stdout_and_stderr = false
      p.start
      assert_equal("stdout\n", p.stdout.read)
      assert_equal("stderr\n", p.stderr.read)
      p.wait
    end
    
    def TODO_test_stdout_and_stderr_with_select
      p = Pebbles::Process.new
      p.command_line = "echo stdout >&1 && echo stderr >&2"
      p.join_stdout_and_stderr = false
      p.start
      while(!(p.stdout.eof? && p.stderr.eof?))
        read = select([p.stdout, p.stderr])
        puts "available #{read}"
        read.each do |io|
          assert_equal("stdout\n", p.stdout.read) if(io == p.stdout)
          assert_equal("stderr\n", p.stderr.read) if(io == p.stderr)
        end
      end
      p.wait
    end
  end
end