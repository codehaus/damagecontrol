require 'test/unit'
require 'rscm/generic_scm_tests'
require 'rscm/svn/svn'
require 'rscm/path_converter'

module RSCM
  class SVNTest < Test::Unit::TestCase
  
    include GenericSCMTests
    include LabelTest

    def create_scm(repository_root_dir, path)
      SVN.new(PathConverter.filepath_to_nativeurl("#{repository_root_dir}/#{path}"), path)
    end

    def test_repourl
      svn = SVN.new("svn+ssh://mooky/bazooka/baluba", "bazooka/baluba")
      assert_equal("svn+ssh://mooky", svn.repourl)

      svn.svnpath = nil
      assert_equal(svn.svnurl, svn.repourl)

      svn.svnpath = ""
      assert_equal(svn.svnurl, svn.repourl)
    end
    
  end
end
