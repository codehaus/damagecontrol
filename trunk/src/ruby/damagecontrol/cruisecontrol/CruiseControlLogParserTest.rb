require 'test/unit'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'
require 'damagecontrol/BuildResult'

module DamageControl
  class CruiseControlLogParserTest < Test::Unit::TestCase
    
    include FileUtils

    def test_successful_build_data
      cc_log_file = damagecontrol_file("testdata/log20030929145347.xml")
      reader = CruiseControlLogParser.new
      build_result = BuildResult.new("dxbranch", ":local:/foo:bar", "dummy command line", "dummy/path", "/dummy/root")
      reader.parse(cc_log_file, build_result)

      assert_equal('dxbranch', build_result.project_name)
      assert_equal('build.698', build_result.label)
      assert_equal('20030929145347', build_result.timestamp)
      assert_equal(false, build_result.successful)
      assert_equal("BUILD FAILED detected", build_result.error_message)
    end
    
  end
end