require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'
require 'damagecontrol/HubTestHelper'

module DamageControl

  class BuildTest < Test::Unit::TestCase
    include FileUtils
    include HubTestHelper

    def test_successful_build

      testrepo = File.expand_path("#{damagecontrol_home}/target/cvstestrepo")

      build = Build.new( \
        "DamageControlled", \
        ":local:#{testrepo}:damagecontrolled", \
        "ant compile", \
        ".", \
        File.expand_path("#{damagecontrol_home}/target/testbuild"))
      
      build.execute(create_hub)

      assert_got_message("DamageControl::BuildProgressEvent")
      assert_got_message("DamageControl::BuildCompleteEvent")
      
    end
  end

end
