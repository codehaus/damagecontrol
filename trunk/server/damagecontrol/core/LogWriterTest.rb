require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class LogWriterTest < Test::Unit::TestCase
    include FileUtils
    include MockIt
    
    def setup
      @hub = new_mock
      @hub.__expect(:add_consumer) do |subscriber|
        assert(subscriber.is_a?(LogWriter))
      end

      @basedir = new_temp_dir
      @writer = LogWriter.new(@hub)
      
      @build = Build.new("project_name")
      @build.log_file = "#{@basedir}/project_name/log/19770614002000.log"
      @build.error_log_file = "#{@basedir}/project_name/log/19770614002000-error.log"

      @build.label = "a_label"
      @build.timestamp = "19770614002000"
    end
    
    def teardown
      @writer.shutdown
    end
    
    def test_writes_error_events_to_ordinary_log_file_AND_special_log_file
      @writer.put(BuildErrorEvent.new(@build, "error"))
      assert(!@writer.error_log_file(@build).closed?)
      assert_file_content("error\n", 
        "#{@basedir}/project_name/log/19770614002000-error.log")
      assert_file_content("error\n", 
        "#{@basedir}/project_name/log/19770614002000.log")
    end

    def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
      @writer.put(BuildProgressEvent.new(@build, "hello"))
      assert(!@writer.log_file(@build).closed?)
      
      @writer.put(BuildCompleteEvent.new(@build))
      assert(@writer.log_file(@build).closed?)

      assert_file_content("hello\n",
        "#{@basedir}/project_name/log/19770614002000.log")
      
    end
    
    def test_closes_all_files_on_build_complete
      @writer.put(BuildProgressEvent.new(@build, "progress"))
      @writer.put(BuildErrorEvent.new(@build, "error"))
      @writer.put(BuildCompleteEvent.new(@build))
      assert(@writer.log_file(@build).closed?)
      assert(@writer.error_log_file(@build).closed?)
    end
    
    def assert_file_content(expected_content, file)
      assert(File.exists?(file), "file doesn't exist: #{file}")
      actual_content = File.read(file)
      assert_equal(expected_content, actual_content)
    end

  end

end