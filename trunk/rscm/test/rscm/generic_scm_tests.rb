require 'fileutils'
require 'rscm/tempdir'
require 'rscm/path_converter'
require 'rscm/difftool_test'

module RSCM

  module GenericSCMTests
    include FileUtils

    def teardown
      @scm.destroy_central if @scm
    end

    #  Acceptance test for scm implementations 
    #
    #  1) Create a central repository
    #  2) Import a test project to the central repository
    #  3) Verify that WorkingCopy is not uptodate (not yet checked out)
    #  4) Check out the contents of the central repo to WorkingCopy
    #  5) Verify that the checked out files were those imported
    #  6) Verify that the initial total revisions (from epoch to infinity) represents those from the import
    #  7) Verify that WorkingCopy is uptodate
    #  8) Change some files in WorkingCopy without committing them (yet)
    #  9) Check out the contents of the central repo to OtherWorkingCopy
    # 10) Verify that OtherWorkingCopy is uptodate
    # 11) Verify that WorkingCopy is uptodate
    # 12) Commit modifications in WorkingCopy
    # 13) Verify that there is one revision since the previous one, and that it corresponds to the changed files in 8.
    # 14) Verify that OtherWorkingCopy is *not* uptodate
    # 15) Check out OtherWorkingCopy
    # 16) Verify that OtherWorkingCopy is now uptodate
    # 17) Add and commit a file in WorkingCopy
    # 18) Verify that the revision (since last revision) for CheckoutHereToo contains only one file
    def test_basics
      work_dir = RSCM.new_temp_dir("basics")
      checkout_dir = "#{work_dir}/WorkingCopy"
      other_checkout_dir = "#{work_dir}/OtherWorkingCopy"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.checkout_dir = checkout_dir

      other_scm = create_scm(repository_dir, "damagecontrolled")
      other_scm.checkout_dir = other_checkout_dir

      raise "This scm (#{scm.name}) can't create 'central' repositories." unless scm.can_create_central?

      # 1
      scm.create_central
      @scm = scm
      assert(scm.name)

      # 2
      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")
      
      # 3
      assert(!scm.uptodate?(nil))
      assert(!scm.uptodate?(nil))
      
      # 4
      yielded_files = []
      files = scm.checkout do |file_name|
        yielded_files << file_name
      end
      
      # 5
      assert_equal(4, files.length)
      assert_equal(files, yielded_files)
      files.sort!
      yielded_files.sort!
      assert_equal(files, yielded_files)

      assert_equal("build.xml", files[0])
      assert_equal("project.xml", files[1])
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", files[2])
      assert_equal("src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java", files[3])

      # 6
      initial_revisions = scm.revisions(nil, nil)
      assert_equal(1, initial_revisions.length)
      initial_revision = initial_revisions[0]
      assert_equal("imported\nsources", initial_revision.message)
      assert_equal(4, initial_revision.length)

      # 7
      assert(scm.uptodate?(initial_revisions.latest.identifier))

      # 8
      change_file(scm, "#{checkout_dir}/build.xml")
      change_file(scm, "#{checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")

      # 9
      other_scm.checkout
      # 10
      assert(other_scm.uptodate?(nil))
      # 11
      assert(scm.uptodate?(nil))
      # 12
      scm.commit("changed\nsomething") 

      # 13
      revisions = scm.revisions(initial_revisions.latest.identifier)

      assert_equal(1, revisions.length, revisions.collect{|cs| cs.to_s})
      revision = revisions[0]
      assert_equal(2, revision.length)

      assert_equal("changed\nsomething", revision.message)

      # why is this nil when running as the dcontrol user on codehaus? --jon
      #assert_equal(username, revision.developer)
      assert(revision.developer)
      assert(revision.identifier)

      assert_equal("build.xml", revision[0].path)
      assert(revision[0].revision)
      assert(revision[0].previous_revision)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", revision[1].path)
      assert(revision[1].revision)
      assert(revision[1].previous_revision)      

      # 14
      assert(!other_scm.uptodate?(revisions.latest.identifier))
      assert(!other_scm.uptodate?(revisions.latest.identifier))
      assert(scm.uptodate?(revisions.latest.identifier))
      assert(scm.uptodate?(revisions.latest.identifier))

      # 15
      files = other_scm.checkout.sort
      assert_equal(2, files.length)
      assert_equal("build.xml", files[0])
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", files[1])

      # 16
      assert(other_scm.uptodate?(nil))
      add_or_edit_and_commit_file(scm, checkout_dir, "src/java/com/thoughtworks/damagecontrolled/Hello.txt", "Bla bla")
      assert(!other_scm.uptodate?(nil))
      revisions = other_scm.revisions(revisions.latest.identifier)
      assert_equal(1, revisions.length)
      assert_equal(1, revisions[0].length)
      assert("src/java/com/thoughtworks/damagecontrolled/Hello.txt", revisions[0][0].path)
      assert("src/java/com/thoughtworks/damagecontrolled/Hello.txt", other_scm.checkout.sort[0])
    end

    def test_create_destroy
      work_dir = RSCM.new_temp_dir("trigger")
      checkout_dir = "#{work_dir}/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "killme")
      scm.checkout_dir = checkout_dir

      (1..3).each do
        assert(!scm.central_exists?)
        scm.create_central
        assert(scm.central_exists?)
        scm.destroy_central
      end

      assert(!scm.central_exists?)
      puts "DONE"
    end
    
    def test_trigger
      work_dir = RSCM.new_temp_dir("trigger")
      checkout_dir = "#{work_dir}/checkout"
      repository_dir = "#{work_dir}/repository"
      trigger_proof = "#{work_dir}/trigger_proof"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.checkout_dir = checkout_dir
      scm.create_central 
      @scm = scm
      
      # Verify that install/uninstall works
      trigger_command = "touch " + PathConverter.filepath_to_nativepath(trigger_proof, false)
      trigger_files_checkout_dir = File.expand_path("#{checkout_dir}/../trigger")
      (1..3).each do |i|
        puts "TRIGGER INSTALL/UNINSTALL CYCLE #{i}"
        assert(!scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
        puts "INSTALL"
        scm.install_trigger(trigger_command, trigger_files_checkout_dir)
        assert(scm.trigger_installed?(trigger_command, trigger_files_checkout_dir))
        puts "UNINSTALL"
        scm.uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      end

      # Verify that the trigger works
      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")
      scm.checkout
      scm.install_trigger(trigger_command, trigger_files_checkout_dir)
      assert(!File.exist?(trigger_proof))

      add_or_edit_and_commit_file(scm, checkout_dir, "afile", "boo")
      assert(File.exist?(trigger_proof))
    end

    def test_checkout_revision_identifier
      work_dir = RSCM.new_temp_dir("ids")
      checkout_dir = "#{work_dir}/checkout"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.checkout_dir = checkout_dir
      scm.create_central
      @scm = scm

      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")
      scm.checkout
      add_or_edit_and_commit_file(scm, checkout_dir, "before.txt", "Before label")
      before_cs = scm.revisions(Time.epoch)

      add_or_edit_and_commit_file(scm, checkout_dir, "after.txt", "After label")
      after_cs = scm.revisions(before_cs.latest.identifier)
      assert_equal(1, after_cs.length)
      assert_equal("after.txt", after_cs[0][0].path)

      scm.checkout(before_cs.latest.identifier)

      assert(File.exist?("#{checkout_dir}/before.txt"))
      assert(!File.exist?("#{checkout_dir}/after.txt"))
    end

    def test_should_allow_creation_with_empty_constructor
      scm = create_scm(RSCM.new_temp_dir, ".")
      scm2 = scm.class.new
      assert_same(scm.class, scm2.class)
    end

    EXPECTED_DIFF = <<EOF
-one two three
-four five six
+one two three four
+five six
EOF
    
    def test_diffs
      work_dir = RSCM.new_temp_dir("diffs")
      checkout_dir = "#{work_dir}/checkout"
      repository_dir = "#{work_dir}/repository"
      import_dir = "#{work_dir}/import/diffing"
      scm = create_scm(repository_dir, "diffing")
      scm.checkout_dir = checkout_dir
      scm.create_central
      @scm = scm
      
      mkdir_p(import_dir)
      File.open("#{import_dir}/afile.txt", "w") do |io|
        io.puts("one two three")
        io.puts("four five six")
      end      
      scm.import_central(import_dir, "Imported a file to diff against")
      scm.checkout

      sleep(1)
      timestamp = Time.now.utc
      sleep(1)

      scm.edit("#{checkout_dir}/afile.txt")
      File.open("#{checkout_dir}/afile.txt", "w") do |io|
        io.puts("one two three four")
        io.puts("five six")
      end
      scm.commit("Modified file to diff")
      revisions = scm.revisions(timestamp)
      
      got_diff = false
      scm.diff(revisions[0][0]) do |diff_io|
        got_diff = true
        diff_string = diff_io.read
        assert_match(/^\-one two three/, diff_string)
        assert_match(/^\-four five six/, diff_string)
        assert_match(/^\+one two three four/, diff_string)
        assert_match(/^\+five six/, diff_string)
      end
      assert(got_diff)
    end

  private

    def import_damagecontrolled(scm, import_copy_dir)
      Log.info("-- IMPORTING INTO CENTRAL REPO --")
      mkdir_p(import_copy_dir)
      path = File.dirname(__FILE__) + "/../../testproject/damagecontrolled"
      path = File.expand_path(path)
      dirname = File.dirname(import_copy_dir)
      cp_r(path, dirname)
      todelete = Dir.glob("#{import_copy_dir}/**/.svn")
      rm_rf(todelete)
      scm.import_central(import_copy_dir, "imported\nsources")
    end
    
    def change_file(scm, file)
      file = File.expand_path(file)
      scm.edit(file)
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
      scm.add(relative_filename) unless existed

      message = existed ? "editing" : "adding"

      sleep(1)
      scm.commit("#{message} #{relative_filename}")
    end
  end
    
  module LabelTest
    def test_label
      work_dir = RSCM.new_temp_dir("label")
      checkout_dir = "#{work_dir}/LabelTest"
      repository_dir = "#{work_dir}/repository"
      scm = create_scm(repository_dir, "damagecontrolled")
      scm.checkout_dir = checkout_dir
      scm.create_central
      @scm = scm

      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")

      scm.checkout

      # TODO: introduce a Revision class which implements comparator methods
      assert_equal(
        "1",
        scm.label 
      )
      change_file(scm, "#{checkout_dir}/build.xml")
      scm.commit("changed something")
      scm.checkout 
      assert_equal(
        "2",
        scm.label 
      )
    end
  end

  module ApplyLabelTest

  end
end
