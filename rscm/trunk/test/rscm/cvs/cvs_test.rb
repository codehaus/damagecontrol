require 'test/unit'
require 'rscm/generic_scm_tests'
require 'rscm/cvs/cvs'

module RSCM
  class CVSTest < Test::Unit::TestCase
    
    include GenericSCMTests
    include ApplyLabelTest
    
    def create_scm(repository_root_dir, path)
      CVS.local(repository_root_dir, path)
    end

    def test_should_fail_on_bad_command
      assert_raise(RuntimeError) do
        CVS.new("").create
      end
    end
  end
end
