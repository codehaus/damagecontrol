require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'

module DamageControl

  class BuildTest < Test::Unit::TestCase
    include FileUtils
    def test_build_failed

      build = Build.new( \
        "DamageControlled", \
        ":local:/foo/bar:zap", \
        "#{ant} compile", \
        ".", \
        nil)

      def build.override_absolute_build_path(abspath)
        @abspath = abspath
      end
      def build.absolute_build_path
        @abspath
      end
      build.override_absolute_build_path(File.expand_path("#{damagecontrol_home}/testdata/damagecontrolled"))
      
      successful = nil
      build.execute { |progress|
        puts "BuildTest:" + progress
        $stdout.flush
        if(/BUILD SUCCESSFUL/ =~ progress)
          successful = true
        end
      }
      assert(successful, "Ant build should succeed")
      
    end
    
  private
  
    def ant
      windows? ? "ant.bat" : "ant"
    end
  end

end
