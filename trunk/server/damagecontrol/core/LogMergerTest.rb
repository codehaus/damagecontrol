require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/LogMerger'
require 'damagecontrol/scm/NoSCM'

module DamageControl  
  class LogMergerTest < Test::Unit::TestCase
    include FileUtils
    
    def test_copies_away_logs_on_build_complete
      hub = MockIt::Mock.new
      hub.__expect(:add_subscriber) do |subscriber|
        assert(subscriber.is_a?(LogMerger))
      end

      basedir = new_temp_dir
      
      build_timestamp = "19770615120000"
      build = Build.new("project", build_timestamp, {
        "logs_to_merge" => [ "target/test-reports/*.xml", "ant-log.xml", "target/logs/*.log" ]
      })
      
      build.xml_log_file = "#{basedir}/project/log/#{build_timestamp}.xml"
      build.scm = NoSCM.new("checkout_dir" => "#{basedir}/checkout")
      
      mkdir_p("#{basedir}/checkout/target/test-reports")
      touch("#{basedir}/checkout/target/test-reports/TEST-com.thoughtworks.Test.xml")
      touch("#{basedir}/checkout/ant-log.xml")
      
      lm = LogMerger.new(hub)
      lm.put(BuildCompleteEvent.new(build))
      
      assert(File.exists?(build.xml_log_file))
      hub.__verify
    end
  end
end