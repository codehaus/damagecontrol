require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class LogWriterTest < Test::Unit::TestCase
    include FileUtils
    include MockIt
    
    def setup
      @hub = new_mock
      @hub.__setup(:add_consumer)

      @basedir = new_temp_dir
      @writer = LogWriter.new(@hub, BuildHistoryRepository.new(@hub, @basedir))
      
      @build = Build.new("project_name")

      @build.label = "a_label"
      @build.dc_creation_time = Time.utc(1977,6,14,0,20,0)
    end
    
    def teardown
      @writer.shutdown
    end
    
    def test_writes_error_events_to_ordinary_log_file_AND_special_log_file
      @writer.put(BuildErrorEvent.new(@build, "error"))
      assert(!@writer.stderr_file(@build).closed?)
      assert_file_content("error\n", 
        "#{@basedir}/project_name/build/19770614002000/stderr.log")
      assert_file_content("error\n", 
        "#{@basedir}/project_name/build/19770614002000/stdout.log")
    end

    def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
      @writer.put(BuildProgressEvent.new(@build, "hello"))
      assert(!@writer.stdout_file(@build).closed?)
      
      @writer.put(BuildCompleteEvent.new(@build))
      assert(@writer.stdout_file(@build).closed?)

      assert_file_content("hello\n",
        "#{@basedir}/project_name/build/19770614002000/stdout.log")
      
    end
    
    def test_closes_all_files_on_build_complete
      @writer.put(BuildProgressEvent.new(@build, "progress"))
      @writer.put(BuildErrorEvent.new(@build, "error"))
      @writer.put(BuildCompleteEvent.new(@build))
      assert(@writer.stdout_file(@build).closed?)
      assert(@writer.stderr_file(@build).closed?)
    end
    
    def assert_file_content(expected_content, file)
      assert(File.exists?(file), "file doesn't exist: #{file}")
      actual_content = File.read(file)
      assert_equal(expected_content, actual_content)
    end

  end

end