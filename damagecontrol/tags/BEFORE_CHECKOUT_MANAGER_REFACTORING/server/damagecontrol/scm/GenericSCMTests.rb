require 'damagecontrol/util/FileUtils'

module DamageControl
  module GenericSCMTests
    include FileUtils

    def create_scm(repository_dir, project_name)
      raise "including classes must implement this method"
    end

    # test_modifiying_one_file_produces_correct_changeset
    # but shitty little windog doesn't like long file names. JEEEEEZ
    # this test is a bit big, it is because there is so much setup and i was lazy.
    def test_1
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/WeCanCallItWhatWeWant/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled") { |line| logger.debug(line) }
      scm.create {|line| logger.debug(line)}

      path = "#{damagecontrol_home}/testdata/damagecontrolled"
      scm.import(path) { |line| logger.debug(line) }
      scm.checkout(checkout_dir) { |line| logger.debug(line) }
      
      # modify file and commit it
      sleep(1)
      time_before = Time.now.utc
      sleep(1)
      change_file("#{checkout_dir}/build.xml")
      change_file("#{checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")
      scm.commit(checkout_dir, "changed something") { |line| logger.debug(line) }
      sleep(1)
      time_after = Time.now.utc
      
      # check that we now have one more change
      changesets = scm.changesets(checkout_dir, time_before, time_after) { |line| logger.debug(line) }

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
    
    
    def test_uptodate
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/WeCanCallItWhatWeWant/checkout"
      other_checkout_dir = "#{work_dir}/SomewhereElse/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled") { |line| logger.debug(line) }
      scm.create {|line| logger.debug(line)}

      path = "#{damagecontrol_home}/testdata/damagecontrolled"
      scm.import(path) { |line| logger.debug(line) }
      scm.checkout(checkout_dir) { |line| logger.debug(line) }
      scm.checkout(other_checkout_dir) { |line| logger.debug(line) }
      
      # modify file and commit it
      sleep(1)
      time_1 = Time.now.utc
      sleep(1)
      change_file("#{other_checkout_dir}/build.xml")
      change_file("#{other_checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")
      scm.commit(other_checkout_dir, "changed something") { |line| logger.debug(line) }
      sleep(1)
      time_2 = Time.now.utc

      assert(!scm.uptodate?(checkout_dir, time_1, time_2))
      sleep(1)
      time_3 = Time.now.utc
      scm.checkout(checkout_dir) { |line| logger.debug(line) }      
      assert(scm.uptodate?(checkout_dir, time_2, time_3))
    end
    
    # test_install_uninstall_install_trigger_should_work_as_many_times_as_we_like
    def test_3
      work_dir = new_temp_dir
      project_name = "OftenModified"
      checkout_dir = "#{work_dir}/#{project_name}/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, project_name) { |line| logger.debug(line) }
      scm.create {|line| logger.debug(line)}
      
      trigger_files_checkout_dir = File.expand_path("#{checkout_dir}/../trigger")
      (1..3).each do
        assert(!scm.trigger_installed?(trigger_files_checkout_dir, project_name))
        scm.install_trigger(
          damagecontrol_home,
          project_name,
          trigger_files_checkout_dir,
          "http://localhost:4713/private/xmlrpc"
        ) {|line| logger.debug(line)}
        assert(scm.trigger_installed?(trigger_files_checkout_dir, project_name))
        scm.uninstall_trigger(trigger_files_checkout_dir, project_name)
      end
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
  end
end