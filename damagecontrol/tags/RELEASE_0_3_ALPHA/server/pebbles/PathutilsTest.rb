require 'test/unit'
require 'pebbles/Pathutils'

module Pebbles
  class PathutilsTest < Test::Unit::TestCase

    include Pebbles::Pathutils

    def test_should_convert_cygwin_path_to_windows_path
      if(cygwin?)
        assert_equal("c:\\scm\\damagecontrol", filepath_to_nativepath("/cygdrive/c/scm/damagecontrol", false))
        # This format is needed when passing to an IO.popen on non-cygwin windows (like windows native svn)
        assert_equal("c:\\\\scm\\\\damagecontrol", filepath_to_nativepath("/cygdrive/c/scm/damagecontrol", true))
      end
    end

    def test_should_convert_cygwin_path_to_windows_url
      if(cygwin?)
        assert_equal("file:///scm/damagecontrol", filepath_to_nativeurl("/cygdrive/c/scm/damagecontrol"))
      end
    end
  
  end
end
