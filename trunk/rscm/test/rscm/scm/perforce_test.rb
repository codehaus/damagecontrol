require 'test/unit'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class PerforceTest < Test::Unit::TestCase
    include FileUtils

    def test_basics
      work_dir = RSCM.new_temp_dir("basics")
      scm = create_scm(work_dir)
      checkout_dir = "#{work_dir}/CheckoutHere"
      other_checkout_dir = "#{work_dir}/CheckoutHereToo"

      import_damagecontrolled(scm, "#{work_dir}/damagecontrolled")

      workspace1 = scm.create_workspace(checkout_dir, "ws1")
      workspace2 = scm.create_workspace(other_checkout_dir, "ws2")

      # test twice - to verify that uptodate? doesn't check out.
      assert(!workspace1.uptodate?(Time.new.utc)) #assert(!scm.uptodate?(checkout_dir, Time.new.utc))
      assert(!workspace1.uptodate?(Time.new.utc)) #assert(!scm.uptodate?(checkout_dir, Time.new.utc))
      yielded_files = []
      files = workspace1.checkout do |file_name| #scm.checkout(checkout_dir) do |file_name|
        yielded_files << file_name
      end

      assert_equal(4, files.length)
      assert_equal(files, yielded_files)
      files.sort!
      yielded_files.sort!
      assert_equal(files, yielded_files)

      assert_equal("build.xml", files[0])
      assert_equal("project.xml", files[1])
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", files[2])
      assert_equal("src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java", files[3])

      initial_changesets = workspace1.changesets(nil, nil) #scm.changesets(checkout_dir, nil, nil)
      assert_equal(1, initial_changesets.length)
      initial_changeset = initial_changesets[0]
      assert_equal("imported\nsources", initial_changeset.message)
      assert_equal(4, initial_changeset.length)
      assert(workspace1.uptodate?(initial_changesets.latest.time + 1))   #scm.uptodate?(checkout_dir, initial_changesets.latest.time + 1))

      # modify file and commit it
      change_file(workspace1, "#{checkout_dir}/build.xml")
      change_file(workspace1, "#{checkout_dir}/src/java/com/thoughtworks/damagecontrolled/Thingy.java")

      workspace2.checkout  #scm.checkout(other_checkout_dir)
      assert(workspace2.uptodate?(Time.new.utc))  #scm.uptodate?(other_checkout_dir, Time.new.utc))
      assert(workspace1.uptodate?(Time.new.utc))  #scm.uptodate?(checkout_dir, Time.new.utc))

      workspace1.commit("changed\nsomething")   #scm.commit(checkout_dir, "changed\nsomething")

      # check that we now have one more change
      changesets = workspace1.changesets(initial_changesets.time + 1) #scm.changesets(checkout_dir, initial_changesets.time + 1)

      assert_equal(1, changesets.length, changesets.collect{|cs| cs.to_s})
      changeset = changesets[0]
      assert_equal(2, changeset.length)

      assert_equal("changed\nsomething", changeset.message)

      # why is this nil when running as the dcontrol user on codehaus? --jon
      #assert_equal(username, changeset.developer)
      assert(changeset.developer)
      assert(changeset.identifier)

      assert_equal("build.xml", changeset[0].path)
      assert(changeset[0].revision)
      assert(changeset[0].previous_revision)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert(changeset[1].revision)
      assert(changeset[1].previous_revision)

      assert(!workspace2.uptodate?(changesets.latest.time+1))
      assert(!workspace2.uptodate?(changesets.latest.time+1))
      assert(workspace1.uptodate?(changesets.latest.time+1))
      assert(workspace1.uptodate?(changesets.latest.time+1))

      files = workspace2.checkout.sort
      assert_equal(2, files.length)
      assert_equal("build.xml", files[0])
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", files[1])

      assert(workspace2.uptodate?(Time.new.utc))

      #add_or_edit_and_commit_file(scm, checkout_dir, "src/java/com/thoughtworks/damagecontrolled/Hello.txt", "Bla bla")
      add_or_edit_and_commit_file(workspace1, checkout_dir, "src/java/com/thoughtworks/damagecontrolled/Hello.txt", "Bla bla")
      assert(!workspace2.uptodate?(Time.new.utc))
      changesets = workspace2.changesets(changesets.time + 1)
      assert_equal(1, changesets.length)
      assert_equal(1, changesets[0].length)
      assert("src/java/com/thoughtworks/damagecontrolled/Hello.txt", changesets[0][0].path)
      assert("src/java/com/thoughtworks/damagecontrolled/Hello.txt", workspace2.checkout.sort[0])
    end

    def create_scm(repository_root_dir, path = nil)
      repository_dir = "#{repository_root_dir}/repository"
      P4Daemon.new(repository_dir).start
      P4Repository.new("localhost:1666")
    end

    def import_damagecontrolled(scm, import_copy_dir)
      mkdir_p(import_copy_dir)
      path = File.dirname(__FILE__) + "/../../../testproject/damagecontrolled" # "/../../testproject/damagecontrolled"
      path = File.expand_path(path)
      dirname = File.dirname(import_copy_dir)
      cp_r(path, dirname)
      todelete = Dir.glob("#{import_copy_dir}/**/.svn")
      rm_rf(todelete)
      scm.import(import_copy_dir, "imported\nsources")
    end

    def change_file(workspace, file) #(scm, file)
      file = File.expand_path(file)
      workspace.edit(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end

    def add_or_edit_and_commit_file(workspace, checkout_dir, relative_filename, content)
      existed = false
      absolute_path = File.expand_path("#{checkout_dir}/#{relative_filename}")
      File.mkpath(File.dirname(absolute_path))
      existed = File.exist?(absolute_path)
      File.open(absolute_path, "w") do |file|
        file.puts(content)
      end
      workspace.add(relative_filename) unless(existed)   #scm.add(checkout_dir, relative_filename) unless(existed)

      message = existed ? "editing" : "adding"

      sleep(1)
      workspace.commit("#{message} #{relative_filename}")  #scm.commit(checkout_dir, "#{message} #{relative_filename}")
    end
  end

  class P4Daemon
    include FileUtils

    def initialize(depotpath)
      @depotpath = depotpath
    end

    def start
      shutdown if running?
      launch
      assert_running
    end

    def assert_running
      raise "p4d did not start properly" if timeout(10) { running? }
    end

    def launch
      fork do
        mkdir_p(@depotpath)
        cd(@depotpath)
        debug "starting p4 server"
        exec("p4d")
      end
      at_exit { shutdown }
    end

    def shutdown
      `p4 -p 1666 admin stop`
    end

    def running?
      !`p4 -p 1666 info`.empty?
    end
  end
end