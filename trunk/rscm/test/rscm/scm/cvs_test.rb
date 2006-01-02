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

  end
end
