require 'test/unit'
require 'ftools'
require 'damagecontrol/FileUtils'
require 'damagecontrol/FilePoller'
require 'damagecontrol/cruisecontrol/CruiseControlLogPoller'

module DamageControl
  class CruiseControlLogPollerTest < Test::Unit::TestCase
    include HubTestHelper
    include FileUtils
    
    def setup
      @dir = "#{damagecontrol_home}/target/polltest/test#{Time.new.to_i}"
      File.mkpath(@dir)
      create_hub
      @log_file = "#{damagecontrol_home}/testdata/log20030929145347.xml"

      @ccpoller = CruiseControlLogPoller.new(hub, @dir)
    end
    
    def teardown
      rmdir(@dir)
    end
    
    def test_new_log_sends_build_complete_event
      @ccpoller.force_tick
      assert_no_messages
      
      File.copy(@log_file, "#{@dir}/log.xml")
      @ccpoller.force_tick
      assert_message_types("DamageControl::BuildCompleteEvent")
      assert_equal('build.698', messages_from_hub[0].build.label)
      assert_equal('20030929145347', messages_from_hub[0].build.timestamp)
      assert_equal(false, messages_from_hub[0].build.successful)
      assert_equal("BUILD FAILED detected", messages_from_hub[0].build.error_message)
    end
    
  end
end