require 'test/unit'
require 'damagecontrol/cruisecontrol/CruiseControlLogParser'
require 'damagecontrol/Build'

module DamageControl
  class CruiseControlLogParserTest < Test::Unit::TestCase
    
    include FileUtils

    def test_successful_build_data
      cc_log_file = "#{damagecontrol_home}/testdata/log20030929145347.xml"
      reader = CruiseControlLogParser.new("http://164.38.244.63:8080/cruisecontrol/buildresults")
      build = Build.new("")
      reader.parse(cc_log_file, build)

      assert_equal('dxbranch', build.project_name)
      assert_equal('build.698', build.label)
      assert_equal('20030929145347', build.timestamp)
      assert_equal(Build::FAILED, build.status)
      assert_equal("BUILD FAILED detected", build.error_message)
      assert_equal("http://164.38.244.63:8080/cruisecontrol/buildresults?log=log20030929145347", build.url)

    end

  end
end
