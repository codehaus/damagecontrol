require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/LogArchiver'
require 'damagecontrol/scm/NoSCM'
require 'damagecontrol/util/HubTestHelper'

module DamageControl  
  class LogArchiverTest < Test::Unit::TestCase
    include HubTestHelper
    include FileUtils
    
    def test_copies_away_logs_on_build_complete
      basedir = new_temp_dir
      create_hub
      
      build_timestamp = "19770615120000"
      build = Build.new("project", build_timestamp, {
        "logs_to_archive" => [ "target/test-reports/*.xml", "ant-log.xml", "target/logs/*.log" ]
      })
      
      build.archive_dir = "#{basedir}/project/archive/#{build_timestamp}"
      build.scm = NoSCM.new("checkout_dir" => "#{basedir}/checkout")
      
      mkdir_p("#{basedir}/checkout/target/test-reports")
      touch("#{basedir}/checkout/target/test-reports/TEST-com.thoughtworks.Test.xml")
      touch("#{basedir}/checkout/ant-log.xml")
      
      LogArchiver.new(hub)
      hub.publish_message(BuildCompleteEvent.new(build))
      
      assert_equal(["#{build.archive_dir}/TEST-com.thoughtworks.Test.xml", "#{build.archive_dir}/ant-log.xml"], Dir["#{build.archive_dir}/*.xml"].sort)
    end
  end
end