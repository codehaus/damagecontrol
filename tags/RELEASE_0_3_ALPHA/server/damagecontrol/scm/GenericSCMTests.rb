require 'damagecontrol/util/FileUtils'

module DamageControl
  module GenericSCMTests
    include FileUtils

    def create_scm
      raise "including classes should implement this method"
    end

    def test_modifiying_one_file_produces_correct_changeset
      scm = create_scm { |line| logger.debug(line) }
      scm.create {|line| logger.debug(line)}
      path = "#{damagecontrol_home}/testdata/damagecontrolled"
      scm.import(path) { |line| logger.debug(line) }
      scm.checkout { |line| logger.debug(line) }
      
      # modify file and commit it
      sleep(1)
      time_before = Time.now.utc
      sleep(1)
      change_file("#{scm.working_dir}/build.xml")
      change_file("#{scm.working_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")
      scm.commit("changed something") { |line| logger.debug(line) }
      sleep(1)
      time_after = Time.now.utc
      
      # check that we now have one more change
      changesets = scm.changesets(time_before, time_after) { |line| logger.debug(line) }

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

      # for debugging only
      scm.install_trigger(
        damagecontrol_home,
        "Whatever",
        "http://localhost:4712/private/xmlrpc"
      ) { |line| logger.debug(line) }
    end
    
    def test_install_uninstall_install_trigger_should_work_as_many_times_as_we_like
      scm = create_scm
      scm.create {|line| logger.debug(line)}

      project_name = "OftenModified"
      
      (1..3).each do
        assert(!scm.trigger_installed?(project_name))
        scm.install_trigger(
          damagecontrol_home,
          project_name,
          "http://localhost:4713/private/xmlrpc"
        ) {|line| logger.debug(line)}
        assert(scm.trigger_installed?(project_name))
        scm.uninstall_trigger(project_name)
      end
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
  end
end