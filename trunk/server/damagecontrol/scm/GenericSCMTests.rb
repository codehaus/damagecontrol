require 'damagecontrol/util/FileUtils'

module DamageControl
  module GenericSCMTests
    include FileUtils

    def create_scm
      raise "including classes should implement this method"
    end

    def test_modifiying_one_file_produces_correct_changeset
      scm = create_scm
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

      assert_equal("changed something\n", changeset.message)
      # why is this nil when running as the dcontrol user on codehaus? --jon
      #assert_equal(username, changeset.developer)
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