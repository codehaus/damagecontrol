require 'test/unit'
require 'pebbles/Pathutils'

module Pebbles
  class PathutilsTest < Test::Unit::TestCase

    include Pebbles::Pathutils

    def test_should_convert_os_path_to_native_path
      p1 = "/cygdrive/c/scm/damagecontrol"
      n1 = p1
      n2 = p1
      if(CYGWIN)
        n1 = "c:\\scm\\damagecontrol"
        # This format is needed when passing to an IO.popen on non-cygwin windows tools (like windows native svn)
        n2 = "c:\\\\scm\\\\damagecontrol"
      end
      assert_equal(n1, filepath_to_nativepath(p1, false))
      assert_equal(n2, filepath_to_nativepath(p1, true))
    end

    def test_should_convert_os_path_to_native_url
      p = "/cygdrive/c/scm/damagecontrol"
      nurl = "file:///cygdrive/c/scm/damagecontrol"
      if(CYGWIN)
        nurl = "file:///c:/scm/damagecontrol"
      end
      assert_equal(nurl, filepath_to_nativeurl(p))
    end
  
  end
end
