require 'test/unit'
require 'stringio'
require 'pebbles/Pathutils'
require 'damagecontrol/scm/GenericSCMTests'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class SVNTest < Test::Unit::TestCase
  
    include Pebbles::Pathutils
    include FileUtils
    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      svn = SVN.new
      svn.svnurl = filepath_to_nativeurl("#{repository_root_dir}/#{path}")
      svn.svnpath = path
      svn
    end

    def test_label
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/blah/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.create {|line| logger.debug(line)}
      now = Time.new.utc
      path = "#{damagecontrol_home}/testdata/damagecontrolled"
      scm.import(path) { |line| logger.debug(line) }
      scm.checkout(checkout_dir, nil) { |line| logger.debug(line) }
      assert_equal(
        "1",
        scm.label(checkout_dir) { |line| logger.debug(line) }
      )
      change_file("#{checkout_dir}/build.xml")
      scm.commit(checkout_dir, "changed something") { |line| logger.debug(line) }
      scm.checkout(checkout_dir, nil) { |line| logger.debug(line) }
      assert_equal(
        "2",
        scm.label(checkout_dir) { |line| logger.debug(line) }
      )
    end
    
    def test_repourl
      svn = SVN.new
      svn.svnurl = "svn+ssh://mooky/bazooka/baluba"
      svn.svnpath = "bazooka/baluba"
      assert_equal("svn+ssh://mooky", svn.repourl)

      svn.svnpath = nil
      assert_equal(svn.svnurl, svn.repourl)

      svn.svnpath = ""
      assert_equal(svn.svnurl, svn.repourl)
    end
    
  end
end
