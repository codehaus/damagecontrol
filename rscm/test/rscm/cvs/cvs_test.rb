require 'test/unit'
require 'rscm/path_converter'
require 'rscm/cvs/cvs'
require 'rscm/generic_scm_tests'

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
        Cvs.new("").create
      end
    end
    
  end
end
