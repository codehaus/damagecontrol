require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/BuildResult'

module DamageControl

  class BuildResultTest < Test::Unit::TestCase
    def test_successful_build
      scm = Mock.new
      filesystem = Mock.new
      reporter = 3
    
      build_result = BuildResult.new( \
        "testproject", \
        scm, \
        "mockscm:whatever", \
        "/our/global/checkoutdir", \
        "echo fake build command", \
        ".", \
        filesystem \
      )
      
      # for some reason we have to put the proc first (?!)
      scm.__next(:checkout) { |proc, scm_path, dir|
        assert_equal(scm_path, "mockscm:whatever")
        assert_equal(dir, "/our/global/checkoutdir/testproject/MAIN")
      }
      filesystem.__next(:chdir) { |dir|
        assert_equal(dir, "/our/global/checkoutdir/testproject/MAIN/.")
      }

      build_result.execute do |line|
        puts "OUTPUT:" + line  
      end
      
      scm.__verify
      filesystem.__verify
#      reporter.__verify
    end
  end

end
