require 'test/unit'
require 'damagecontrol/LogWriter'
require 'ftools'

module DamageControl

	class LogWriterTest < Test::Unit::TestCase
		
		def setup
			@hub = Hub.new
			@writer = LogWriter.new(@hub)
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
			
			rmdir("tmp.log")
			rmdir("logs")
		end
		
		def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
			@hub.publish_message(BuildRequestEvent.new(@build))
			assert(@writer.current_log.is_a?(IO))
			assert(!@writer.current_log.closed?)
			@hub.publish_message(BuildCompleteEvent.new(@build))
			assert(@writer.current_log.closed?)
		end

		def test_log_writer_outputs_logs_to_correct_log_file
			@clock.change_time(4711)
			@hub.publish_message(BuildRequestEvent.new(@build))
			@hub.publish_message(BuildProgressEvent.new(@build, "line 1"))
			@hub.publish_message(BuildProgressEvent.new(@build, "line 2"))
			@hub.publish_message(BuildCompleteEvent.new(@build))
			assert(FileTest::exists?("logs/4711.log"))
			File.open("logs/4711.log") { |f|
				assert_equal("line 1\nline 2\n", f.gets(nil))
			}
		end
		
		include FileUtils
	end
end