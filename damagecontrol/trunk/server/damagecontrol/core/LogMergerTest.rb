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
      
      log_xml = "#{basedir}/build/19770615120000/log.xml"
      
      mkdir_p("#{basedir}/checkout/target/test-reports")
      touch("#{basedir}/checkout/target/test-reports/TEST-com.thoughtworks.Test.xml")
      touch("#{basedir}/checkout/ant-log.xml")
      
      build_history_repository = new_mock
      build_history_repository.__expect(:checkout_dir) { "#{basedir}/checkout" }
      build_history_repository.__expect(:xml_log_file) { log_xml }

      lm = LogMerger.new(
        hub,
        build_history_repository
      )
      lm.put(BuildCompleteEvent.new(build))
      
      assert(File.exists?(log_xml))
    end
  end
end