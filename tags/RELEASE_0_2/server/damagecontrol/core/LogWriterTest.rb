require 'test/unit'
require 'damagecontrol/core/LogWriter'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class LogWriterTest < Test::Unit::TestCase
    include FileUtils
    
    def setup
      @hub = Hub.new
      @basedir = new_temp_dir
      @project_directories = ProjectDirectories.new(@basedir)
      @writer = LogWriter.new(@hub, @project_directories)
      
      @build = Build.new("project_name")

      @build.label = "a_label"
      @build.timestamp = "19770614002000"
    end

    def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
      progress_event = BuildProgressEvent.new(@build, "hello")
      @hub.publish_message(progress_event)
      assert(!@writer.log_file(@build).closed?)
      
      complete_event = BuildCompleteEvent.new(@build)
      @hub.publish_message(complete_event)
      assert(@writer.log_file(@build).closed?)

      assert_file_content("hello\n", 
        "#{@basedir}/project_name/log/19770614002000.log")
      
    end
    
    def assert_file_content(expected_content, file)
      assert(File.exists?(file), "file doesn't exist: #{file}")
      actual_content = nil
      File.open(file) do |io|
        actual_content = io.gets(nil)
      end
      assert_equal(expected_content, actual_content)
    end

  end

end