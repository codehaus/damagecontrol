require 'test/unit'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class SubversionTest < Test::Unit::TestCase
  
    include GenericSCMTests
    include LabelTest

    def create_scm(repository_root_dir, path)
      Subversion.new(PathConverter.filepath_to_nativeurl("#{repository_root_dir}/#{path}"), path)
    end

    def test_repourl
      svn = Subversion.new("svn+ssh://mooky/bazooka/baluba", "bazooka/baluba")
      assert_equal("svn+ssh://mooky", svn.repourl)

      svn.path = nil
      assert_equal(svn.url, svn.repourl)

      svn.path = ""
      assert_equal(svn.url, svn.repourl)
    end
    
  end
end
