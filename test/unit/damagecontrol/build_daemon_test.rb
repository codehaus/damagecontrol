require File.dirname(__FILE__) + '/../../test_helper'

module DamageControl  
  class BuildDaemonTest < Test::Unit::TestCase

    def setup
      Project.delete_all
      Revision.delete_all
      Build.delete_all
      FileUtils.rm_rf(DAMAGECONTROL_HOME)
    end
    
    def new_dir(dir)
      dir = File.expand_path(dir)
      FileUtils.rm_r(dir) if File.exist?(dir)
      FileUtils.mkdir_p(dir)
      dir
    end
    
    def central_repo
      @repo_dir = new_dir(RAILS_ROOT + "/target/integration/daemon/central") unless @repo_dir
      @repo_dir
    end

    def checkout_dir
      @checkout_dir = new_dir(RAILS_ROOT + "/target/integration/daemon/local") unless @checkout_dir
      @checkout_dir
    end
    
    def create_file(file, content)
      File.open(file, "w") do |io|
        io.write(content)
      end
    end

    def test_should_execute_build_when_change_committed      
      daemon = BuildDaemon.new
      
      # create new project
      archiver = ::DamageControl::Publisher::ArtifactArchiver.new
      archiver.files = {"result.txt" => "Test"}
      archiver.enabling_states = [Build::Successful.new]
      
      scm = RSCM::Subversion.new
      scm.url = "file://#{central_repo}"
      project = Project.create(:name => "Test", :scm => scm, :publishers => [archiver], :build_command => 'cp input.txt result.txt')
      
      # create svn repository
      scm.create_central

      # nothing should have happened yet
      daemon.run_once
      assert_equal(0, project.revisions.length)
      
      # check out, change file and commit
      scm.checkout_dir = checkout_dir
      scm.checkout
      create_file(checkout_dir + "/input.txt", "This is a test")
      scm.add("input.txt")
      scm.commit("This is just a test")
      
      # this should execute a build
      daemon.run_once

      # check build executed
      project.reload
      assert_equal(1, project.revisions.length)
      assert_equal(1, project.latest_revision.builds.length)
      assert(project.latest_revision.builds[0].successful?)
      assert_equal("This is a test", File.open(Artifact::ROOT_DIR + "/result.txt").read)
    end

  end
end