require 'damagecontrol/util/FileUtils'

module DamageControl
  module GenericSCMTests
    include FileUtils

    def create_scm(repository_root_dir, path)
      raise "including classes must implement this method"
    end

    # test_modifiying_one_file_produces_correct_changeset
    # but shitty little windog doesn't like long file names. JEEEEEZ
    # this test is a bit big, it is because there is so much setup and i was lazy.
    def test_1
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/WeCanCallItWhatWeWant/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled") { |line| logger.info(line) }
      scm.create {|line| logger.info(line)}
      path = "#{damagecontrol_home}/testdata/damagecontrolled"
      import_dir = "#{work_dir}/damagecontrolled"
      copy_dir(path, import_dir)

      before_import = Time.new.utc
      sleep(1)
      scm.import(import_dir) { |line| logger.info(line) }
      sleep(1)
      after_import = Time.new.utc
      files = scm.checkout(checkout_dir, nil) { |line| logger.info(line) }
      changesets = scm.changesets(checkout_dir, before_import, after_import, files)
      
      # modify file and commit it
      sleep(1)
      before_change = Time.now.utc
      sleep(1)
      change_file("#{checkout_dir}/build.xml")
      change_file("#{checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")
      scm.commit(checkout_dir, "changed something") { |line| logger.info(line) }
      
      # check that we now have one more change
      changesets = scm.changesets(checkout_dir, before_change, nil, nil) { |line| logger.info(line) }

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
      scm = create_scm(repository_dir, "damagecontrolled") { |line| logger.info(line) }
      scm.create {|line| logger.info(line)}
      path = "#{damagecontrol_home}/testdata/damagecontrolled"

      scm.import(path)
      assert(0, scm.checkout(checkout_dir, nil).length)
      assert(0, scm.checkout(other_checkout_dir, nil).length)
      
      # modify file and commit it
      sleep(1)
      before_change = Time.now.utc
      sleep(1)
      change_file("#{other_checkout_dir}/build.xml")
      change_file("#{other_checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")
      scm.commit(other_checkout_dir, "changed something")
      sleep(1)
      after_change = Time.now.utc

      changesets = scm.changesets(checkout_dir, before_change, after_change, nil) { |line| puts line }
      assert(1, changesets.length)
      
      assert(before_change < changesets[0].time)
      assert(changesets[0].time < after_change)

      assert_equal("build.xml", changesets[0][0].path)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changesets[0][1].path)
    end
    
    # test_install_uninstall_install_trigger_should_work_as_many_times_as_we_like
    def test_3
      work_dir = new_temp_dir
      path = "OftenModified"
      checkout_dir = "#{work_dir}/#{path}/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, path)
      scm.create {|line| logger.info(line)}
      
      trigger_files_checkout_dir = File.expand_path("#{checkout_dir}/../trigger")
      trigger_command = "bla bla"
      (1..3).each do
        assert(!scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
        scm.install_trigger(trigger_command, trigger_files_checkout_dir)
        assert(scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
        scm.uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      end
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
  end
end