require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/LogWriter'
require 'ftools'
require 'stringio'

module DamageControl

  class LogWriterTest < Test::Unit::TestCase
    
    def setup
      @hub = Hub.new
      @file_system = Mock.new
      @writer = LogWriter.new(@hub, @file_system)
      @build = Build.new(nil, "project", nil)
      @build.logs_directory = "logs"
      @clock = FakeClock.new
      @writer.clock = @clock
    end
    
    def teardown
      begin
        @writer.current_log.close
      rescue
      end
    end
    
    def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
      @file_system.__next(:newFile) { |file_name, rw|
        StringIO.new
      }

      @hub.publish_message(BuildRequestEvent.new(@build))
      assert(!@writer.current_log.closed?)
      @hub.publish_message(BuildCompleteEvent.new(@build))
      assert(@writer.current_log.closed?)
    end

    def test_log_writer_outputs_logs_to_correct_log_file
      in_memory_file = StringIO.new
      
      # overriding this because close removes the content
      def in_memory_file.close
      end
      
      @file_system.__next(:newFile) { |file_name, rw|
        assert_equal("logs/4711.log", file_name)
        in_memory_file
      }

      @clock.change_time(4711)
      @hub.publish_message(BuildRequestEvent.new(@build))
      @hub.publish_message(BuildProgressEvent.new(@build, "line 1"))
      @hub.publish_message(BuildProgressEvent.new(@build, "line 2"))
      @hub.publish_message(BuildCompleteEvent.new(@build))

      assert_equal("line 1\nline 2\n", in_memory_file.string)
      @file_system.__verify
    end
  end
end