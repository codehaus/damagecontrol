require 'test/unit'
require 'damagecontrol/scm/GenericSCMTests'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class SVNTest < Test::Unit::TestCase
  
    include FileUtils
    include GenericSCMTests

    def create_scm(repository_dir, path)
      LocalSVN.new(repository_dir, path)
    end

    def test_label
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/blah/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled") { |line| logger.debug(line) }
      scm.create {|line| logger.debug(line)}

      path = "#{damagecontrol_home}/testdata/damagecontrolled"
      scm.import(path) { |line| logger.debug(line) }
      scm.checkout(checkout_dir) { |line| logger.debug(line) }
      assert_equal(
        "1",
        scm.label(checkout_dir) { |line| logger.debug(line) }
      )
      change_file("#{checkout_dir}/build.xml")
      scm.commit(checkout_dir, "changed something") { |line| logger.debug(line) }
      assert_equal(
        "2",
        scm.label(checkout_dir) { |line| logger.debug(line) }
      )
    end
    
  end
end
