require 'test/unit'
require 'rscm/path_converter'
require 'rscm'
require 'rscm/generic_scm_tests'
require 'stringio'

module RSCM

  class Cvs
    # Convenience factory method used in testing
    def Cvs.local(cvsroot_dir, mod)
      cvsroot_dir = PathConverter.filepath_to_nativepath(cvsroot_dir, true)
      Cvs.new(":local:#{cvsroot_dir}", mod)
    end
  end
  
  class CvsTest < Test::Unit::TestCase
    
    include GenericSCMTests
    include ApplyLabelTest
    
    def create_scm(repository_root_dir, path)
      Cvs.local(repository_root_dir, path)
    end

    def test_should_fail_on_bad_command
      assert_raise(RuntimeError) do
        Cvs.new("").create_central
      end
    end
    
    LS_LOG = <<-EOF
---- 2005-11-22 21:24:40 -0500 1.1        afile
---- 2005-11-22 22:04:20 -0500 1.2        build.xml
---- 2005-11-22 22:12:43 -0500 1.1        foo bar
---- 2005-11-22 21:24:37 -0500 1.1.1.1    1.1 project.xml
d--- 2005-11-22 22:12:43 -0500            1.1 src
d--- 2005-11-22 22:12:43 -0500            togo
EOF
    def test_should_parse_ls_log
      history_files = Cvs.new.parse_ls_log(StringIO.new(LS_LOG), "")
      assert_equal("afile", history_files[0].relative_path)
      assert_equal("foo bar", history_files[2].relative_path)
      assert_equal("1.1 project.xml", history_files[3].relative_path)
      assert(!history_files[3].directory?)
      assert_equal("1.1 src", history_files[4].relative_path)
      assert(history_files[4].directory?)
      assert_equal("togo", history_files[5].relative_path)
      assert(history_files[5].directory?)
    end
  end
end
