require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/LogMerger'
require 'damagecontrol/scm/NoSCM'

module DamageControl  
  class LogMergerTest < Test::Unit::TestCase
    include FileUtils
    include MockIt
    
    def test_copies_away_logs_on_build_complete
      hub = new_mock
      hub.__expect(:add_consumer) do |subscriber|
        assert(subscriber.is_a?(LogMerger))
      end

      basedir = new_temp_dir
      
      build = Build.new("project", {
        "logs_to_merge" => [ "target/test-reports/*.xml", "ant-log.xml", "target/logs/*.log" ]
      })
      build.dc_start_time = Time.utc(1977,6,15,12,0,0,0)
      
      build.xml_log_file = "#{basedir}/project/log/19770615120000.xml"
      
      mkdir_p("#{basedir}/checkout/target/test-reports")
      touch("#{basedir}/checkout/target/test-reports/TEST-com.thoughtworks.Test.xml")
      touch("#{basedir}/checkout/ant-log.xml")
      
      lm = LogMerger.new(
        hub,
        new_mock.__expect(:checkout_dir) { "#{basedir}/checkout" }
      )
      lm.put(BuildCompleteEvent.new(build))
      
      assert(File.exists?(build.xml_log_file))
    end
  end
end