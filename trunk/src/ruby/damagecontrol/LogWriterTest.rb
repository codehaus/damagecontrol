require 'test/unit'
require 'damagecontrol/LogWriter'

module DamageControl

	class LogWriterTest < Test::Unit::TestCase
		
		def setup
			@hub = Hub.new
			@writer = LogWriter.new(@hub)
			@project = Project.new("project")
			@project.logs_directory = "logs"
			@clock = FakeClock.new
			@writer.clock = @clock
		end
		
		def teardown
			begin
				@writer.current_log.close
				delete("tmp.log")
				delete("logs")
			rescue
			end
		end
		
		def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
			@hub.publish_message(BuildRequestEvent.new(@project))
			assert(@writer.current_log.is_a?(IO))
			assert(!@writer.current_log.closed?)
			@hub.publish_message(BuildCompleteEvent.new(@project))
			assert(@writer.current_log.closed?)
		end

		def test_log_writer_outputs_logs_to_correct_log_file
			@clock.change_time(4711)
			@hub.publish_message(BuildRequestEvent.new(@project))
			@hub.publish_message(BuildProgressEvent.new(@project, "line 1"))
			@hub.publish_message(BuildProgressEvent.new(@project, "line 2"))
			@hub.publish_message(BuildCompleteEvent.new(@project))
			assert(FileTest::exists?("logs/4711.log"))
			File.open("logs/4711.log") { |f|
				assert_equal("line 1\nline 2\n", f.gets(nil))
			}
		end
		
		include FileUtils
	end
end