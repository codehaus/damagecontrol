require 'test/unit'
require 'ftools'
require 'fileutils'
require 'stringio'

module DamageControl
  class AbstractSCMTest < Test::Unit::TestCase
    include ::FileUtils
    include FileUtils

    # Subclasses should override this method  
    def create_scm
      nil
    end

    def test_modifiying_one_file_produces_correct_changeset
      scm = create_scm
      return unless scm
      scm.create
      scm.import("#{damagecontrol_home}/testdata/damagecontrolled")
      scm.checkout
      
      # modify file and commit it
      sleep(1)
      time_before = Time.now.utc
      sleep(1)
      change_file("#{scm.working_dir}/build.xml")
      change_file("#{scm.working_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")
      scm.commit("changed something")
      sleep(1)
      time_after = Time.now.utc
      
      # check that we now have one more change
      changesets = scm.changesets(time_before, time_after)

      assert_equal(1, changesets.length)
      changeset = changesets[0]
      assert_equal(2, changeset.length)

      assert_equal("changed something", changeset.message)
      assert(changeset.developer)
      assert(changeset.revision)

      assert_equal("build.xml", changeset[0].path)
      assert(changeset[0].revision)
      assert(changeset[0].previous_revision)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert(changeset[1].revision)
      assert(changeset[1].previous_revision)
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
  end
end