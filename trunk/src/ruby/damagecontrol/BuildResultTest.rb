require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/BuildResult'

module DamageControl

  class BuildResultTest < Test::Unit::TestCase
    def test_successful_build

      testrepo = File.expand_path("target/cvstestrepo")

      build_result = BuildResult.new( \
        "DamageControlled", \
        ":local:#{testrepo}:damagecontrolled", \
        "ant", \
        ".", \
        File.expand_path("target/testbuild"))
      
      build_result.execute do |line|
        puts "OUTPUT:" + line
        $stdout.flush
      end
      
    end
  end

end
