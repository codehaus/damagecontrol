require 'test/unit'
require 'ftools'
require 'pebbles/mockit'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/FilePoller'
require 'damagecontrol/cruisecontrol/CruiseControlLogPoller'

module DamageControl
  class CruiseControlLogPollerTest < Test::Unit::TestCase
    include FileUtils
    
    def setup
      @mock_hub = MockIt::Mock.new
      @dir = "#{damagecontrol_home}/testdata"
      @log_file = "#{@dir}/log20030929145347.xml"
      @ccpoller = CruiseControlLogPoller.new(@mock_hub, @dir, "http://164.38.244.63:8080/cruisecontrol/buildresults")
    end
    
    def test_new_log_sends_build_complete_event
      @mock_hub.__expect(:publish_message) do |message|
        assert(message.is_a?(BuildCompleteEvent))
        assert_equal('build.698', message.build.label)
        assert_equal('20030929145347', message.build.timestamp)
        assert_equal(Build::FAILED, message.build.status)
        assert_equal("BUILD FAILED detected", message.build.error_message)
      end
      @ccpoller.new_file(@log_file)
      @mock_hub.__verify
    end
    
  end
end
