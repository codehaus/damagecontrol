
require 'test/unit'
require 'damagecontrol/FilePoller'
require 'damagecontrol/FileUtils'

module DamageControl
	
	class FilePollerTest < Test::Unit::TestCase
		include FileUtils
				
		class TestFilePoller < FilePoller
			attr_reader :new_files
			
			def initialize(dir)
				super(dir)
				@new_files = []
			end
			
			def new_file(file)
				@new_files<<file
			end
		end

		def setup
			@dir = "FilePoller"
			mkdirs(@dir)
			@poller = TestFilePoller.new(@dir)
		end

		def teardown
			delete(@dir)
		end
		
		def test_doesnt_trig_on_empty_directory
			@poller.tick(@poller.clock.current_time)
			assert_equal([], @poller.new_files)
		end
		
		def test_checks_peridoically
			@poller.clock = FakeClock.new
			@poller.clock.change_time(4711)
			@poller.tick(@poller.clock.current_time)
			assert_equal(4711 + 1000, @poller.next_tick)
		end
		
		def test_new_file_calls_new_file
			create_file("newfile")
			@poller.tick(@poller.clock.current_time)
			assert_equal(["#{@dir}/newfile"], @poller.new_files)
		end
		
		def create_file(filename)
			File.open("#{@dir}/#{filename}", "w") do |file|
				file.puts "bajs"
			end
		end
		
		def test_two_newfiles_calls_new_file_for_each
			create_file("newfile1")
			@poller.tick(@poller.clock.current_time)
			assert_equal(["#{@dir}/newfile1"], @poller.new_files)
			@poller.new_files.clear
			assert_equal([], @poller.new_files)

			create_file("newfile2")
			@poller.tick(@poller.clock.current_time)
			assert_equal(["#{@dir}/newfile2"], @poller.new_files)
		end
	end

end