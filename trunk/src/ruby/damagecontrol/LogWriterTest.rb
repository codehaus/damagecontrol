require 'test/unit'
require 'damagecontrol/LogWriter'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'

module DamageControl

  class LogWriterTest < Test::Unit::TestCase
    include FileUtils
    
    def setup
      @hub = Hub.new

      @writer = LogWriter.new(@hub)
      
      @build = Build.new("plopp", ":local:/foo/bar:zap", nil, nil, "#{damagecontrol_home}/target/logwritertest")
      @build.label = "a_label"
    end

    def test_log_writer_creates_new_log_on_build_request_and_closes_it_on_build_complete
      bre = BuildProgressEvent.new(@build, "hello")
      @hub.publish_message(bre)
      assert(!@writer.log_file(bre).closed?)

      bce = BuildCompleteEvent.new(@build)
      @hub.publish_message(bce)
      assert(@writer.log_file(bce).closed?)
    end

  end

end