require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/LogMerger'
require 'damagecontrol/scm/NoSCM'
require 'damagecontrol/util/HubTestHelper'

module DamageControl  
  class LogMergerTest < Test::Unit::TestCase
    include HubTestHelper
    include FileUtils
    
    def test_copies_away_logs_on_build_complete
      basedir = new_temp_dir
      create_hub
      
      build_timestamp = "19770615120000"
      build = Build.new("project", build_timestamp, {
        "logs_to_merge" => [ "target/test-reports/*.xml", "ant-log.xml", "target/logs/*.log" ]
      })
      
      build.xml_log_file = "#{basedir}/project/log/#{build_timestamp}.xml"
      build.scm = NoSCM.new("checkout_dir" => "#{basedir}/checkout")
      
      mkdir_p("#{basedir}/checkout/target/test-reports")
      touch("#{basedir}/checkout/target/test-reports/TEST-com.thoughtworks.Test.xml")
      touch("#{basedir}/checkout/ant-log.xml")
      
      LogMerger.new(hub)
      hub.publish_message(BuildCompleteEvent.new(build))
      
      assert(File.exists?(build.xml_log_file))
    end
  end
end