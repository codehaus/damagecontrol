require 'fileutils'

module RSCM
  module GenericSCMTests
    include FileUtils

    # Acceptance test for scm implementations 
    #
    #  1) Create a repo
    #  2) Import a test project
    #  3) Verify that CheckoutHere is not uptodate
    #  4) Check out to CheckoutHere
    #  5) Verify that the checked out files were those imported
    #  6) Verify that the initial total changesets (from epoch to infinity) represents those from the import
    #  7) Verify that CheckoutHere is uptodate
    #  8) Change some files in DeveloperOne's working copy
    #  9) Check out to CheckoutHereToo
    # 10) Verify that CheckoutHereToo is uptodate
    # 11) Verify that CheckoutHere is uptodate
    # 12) Commit modifications in CheckoutHere is uptodate
    # 13) Verify that CheckoutHere is uptodate
    # 14) Verify that CheckoutHereToo is not uptodate
    # 15) Check out to CheckoutHereToo
    # 16) Verify that CheckoutHereToo is uptodate
    # 17) Add and commit a file in CheckoutHere
    # 18) Verify that the changeset (since last changeset) for CheckoutHereToo contains only one file
    def test_basics
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/CheckoutHere"
      other_checkout_dir = "#{work_dir}/CheckoutHereToo"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled") 
      scm.create
      assert(scm.name)

      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")

      # test twice - to verify that uptodate? doesn't check out.
      assert(!scm.uptodate?(checkout_dir))
      assert(!scm.uptodate?(checkout_dir))
      files = scm.checkout(checkout_dir) 

      assert_equal(4, files.length)
      assert_equal("build.xml", files[0])
      assert_equal("project.xml", files[1])
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", files[2])
      assert_equal("src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java", files[3])
      initial_changesets = scm.changesets(checkout_dir, nil, nil, files)

      assert_equal(1, initial_changesets.length)
      initial_changeset = initial_changesets[0]
      assert_equal(4, initial_changeset.length)
      assert_equal("imported sources", initial_changeset.message)
      assert(scm.uptodate?(checkout_dir))

      # modify file and commit it
      change_file("#{checkout_dir}/build.xml")
      change_file("#{checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")

      scm.checkout(other_checkout_dir, nil) 
      assert(scm.uptodate?(other_checkout_dir))
      assert(scm.uptodate?(checkout_dir))

      scm.commit(checkout_dir, "changed something") 

      # check that we now have one more change
      changesets = scm.changesets(checkout_dir, initial_changesets.time + 1, nil, nil) 

      assert_equal(1, changesets.length)
      changeset = changesets[0]
      assert_equal(2, changeset.length)

      assert_equal("changed something", changeset.message)
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

      assert(!scm.uptodate?(other_checkout_dir))
      assert(!scm.uptodate?(other_checkout_dir))
      assert(scm.uptodate?(checkout_dir))
      assert(scm.uptodate?(checkout_dir))

      files = scm.checkout(other_checkout_dir, nil) 
      assert_equal(2, files.length)
      assert_equal("build.xml", files[0])
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", files[1])

      assert(scm.uptodate?(other_checkout_dir))

      add_or_edit_and_commit_file(scm, checkout_dir, "src/java/com/thoughtworks/damagecontrolled/Hello.txt", "Bla bla")
      assert(!scm.uptodate?(other_checkout_dir))
      changesets = scm.changesets(other_checkout_dir, changesets.time + 1, nil, nil)
      assert_equal(1, changesets.length)
      assert_equal(1, changesets[0].length)
      assert("src/java/com/thoughtworks/damagecontrolled/Hello.txt", changesets[0][0].path)
      assert("src/java/com/thoughtworks/damagecontrolled/Hello.txt", scm.checkout(other_checkout_dir)[0])
    end
    
    def Xtest_trigger
      work_dir = new_temp_dir
      path = "OftenModified"
      checkout_dir = "#{work_dir}/#{path}/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, path)
      scm.create 
      
      trigger_files_checkout_dir = File.expand_path("#{checkout_dir}/../trigger")
      trigger_command = "bla bla"
      (1..3).each do
        assert(!scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
        scm.install_trigger(trigger_command, trigger_files_checkout_dir)
        assert(scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
        scm.uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      end
    end
    
    def Xtest_label
      work_dir = new_temp_dir
      checkout_dir = "#{work_dir}/LabelTest"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.create

      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")

      scm.checkout(checkout_dir)

      # Some SCMs don't support labels, so we just return
      return if scm.label(checkout_dir).nil?

      # TODO: introduce a Revision class which implements comparator methods
      assert_equal(
        "1",
        scm.label(checkout_dir) 
      )
      change_file("#{checkout_dir}/build.xml")
      scm.commit(checkout_dir, "changed something") 
      scm.checkout(checkout_dir, nil) 
      assert_equal(
        "2",
        scm.label(checkout_dir) 
      )
    end

  private

    def new_temp_dir
      identifier = identifier.to_s
      identifier.gsub!(/\(|:|\)/, '_')
      dir = File.dirname(__FILE__) + "/../../target/temp_#{identifier}_#{Time.new.to_i}"
      mkdir_p(dir)
      dir
    end

    def import_damagecontrolled(scm, import_copy_dir)
      mkdir_p(import_copy_dir)
      path = File.dirname(__FILE__) + "/../../testproject/damagecontrolled"
      path = File.expand_path(path)
      cp_r(path, File.dirname(import_copy_dir))
      todelete = Dir.glob("#{import_copy_dir}/**/.svn")
      rm_rf(todelete)
      scm.import(import_copy_dir, "imported sources")
    end
    
    def change_file(file)
      file = File.expand_path(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end

    def add_or_edit_and_commit_file(scm, checkout_dir, relative_filename, content)
      existed = false
      absolute_path = File.expand_path("#{checkout_dir}/#{relative_filename}")
      File.mkpath(File.dirname(absolute_path))
      existed = File.exist?(absolute_path)
      File.open(absolute_path, "w") do |file|
        file.puts(content)
      end
      scm.add(checkout_dir, relative_filename) unless(existed)

      message = existed ? "editing" : "adding"

      scm.commit(checkout_dir, "#{message} #{relative_filename}")
    end

  end
end