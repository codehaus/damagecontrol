require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/LogWriter'
require 'damagecontrol/BuildResult'
require 'ftools'
require 'stringio'

module DamageControl

  class LogWriterTest < Test::Unit::TestCase
    
    def setup
      @hub = Hub.new
      @file_system = Mock.new
      @scm = Mock.new

      @writer = LogWriter.new(@hub, @file_system)
      
      @build = BuildResult.new("plopp", ":local:/foo/bar:zap", nil, nil, "/some/where")
      @build.label = "a_label"
    end

    def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
      fake_file = StringIO.new
      @file_system.__next(:newFile) { |file_name, rw|
        assert_equal("/some/where/plopp/zap/MAIN/logs/a_label.log", file_name)
        fake_file
      }

      bre = BuildProgressEvent.new(@build, "hello")
      @hub.publish_message(bre)
      assert(!@writer.log_file(bre).closed?)

      bce = BuildCompleteEvent.new(@build)
      @hub.publish_message(bce)
      assert(@writer.log_file(bce).closed?)
    end

  end

end