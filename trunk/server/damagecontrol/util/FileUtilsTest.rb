require 'test/unit'

require 'damagecontrol/util/FileUtils'

class FileUtilsTest < Test::Unit::TestCase
  
  include FileUtils
  
  def test_can_execute_echo_command
    result = ""
    cmd_with_io(".", "echo hello world") do |io|
      io.each_line {|line| result += line}
    end
    assert_equal("hello world\n", result)
  end
  
  def TODO_test_can_read_error_output
    result = ""
    p = Pebbles::Process.new
    p.command_line = "echo hello world 2>&1"
    p.execute {|stdin, stdout, stderr| stderr.each_line {|line| result += line} }
    assert_equal("hello world\n", result)
  end
  
end