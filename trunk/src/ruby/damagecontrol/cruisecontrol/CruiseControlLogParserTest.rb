require 'test/unit'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'
require 'damagecontrol/Build'

module DamageControl
  class CruiseControlLogParserTest < Test::Unit::TestCase
    
    include FileUtils

    def test_successful_build_data
      cc_log_file = "#{damagecontrol_home}/testdata/log20030929145347.xml"
      reader = CruiseControlLogParser.new
      build = Build.new("dxbranch")
      reader.parse(cc_log_file, build)

      assert_equal('dxbranch', build.project_name)
      assert_equal('build.698', build.label)
      assert_equal('20030929145347', build.timestamp)
      assert_equal(Build::FAILED, build.status)
      assert_equal("BUILD FAILED detected", build.error_message)
    end
    
  end
end