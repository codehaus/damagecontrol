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
      
      archive_dir = "#{basedir}/project/archive/#{build_timestamp}"
      
      mock_project_config_repository = MockIt::Mock.new
      mock_project_config_repository.__expect(:archive_dir) do |project_name, timestamp|
        assert_equal("project", project_name)
        assert_equal(build_timestamp, timestamp)
        archive_dir
      end
      
      build.scm = NoSCM.new("checkout_dir" => "#{basedir}/checkout")
      
      mkdir_p("#{basedir}/checkout/target/test-reports")
      touch("#{basedir}/checkout/target/test-reports/TEST-com.thoughtworks.Test.xml")
      touch("#{basedir}/checkout/ant-log.xml")
      
      LogArchiver.new(hub, mock_project_config_repository)
      hub.publish_message(BuildCompleteEvent.new(build))
      
      assert_equal(["#{archive_dir}/TEST-com.thoughtworks.Test.xml", "#{archive_dir}/ant-log.xml"], Dir["#{archive_dir}/*.xml"].sort)
      
      mock_project_config_repository.__verify
    end
  end
end