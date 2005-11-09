require File.dirname(__FILE__) + '/../../test_helper'
require 'stringio'

module DamageControl  
  class BuildDaemonTest < Test::Unit::TestCase
    include Platform
    self.use_transactional_fixtures = false

    def setup
      Project.delete_all
      Revision.delete_all
      Build.delete_all
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
      log = StringIO.new
      
      BuildDaemon.logger = Logger.new(log)
      ScmPoller.logger = Logger.new(log)

      daemon = BuildDaemon.new(ScmPoller.new)
      
      # create new project
      archiver = ::DamageControl::Publisher::ArtifactArchiver.new
      archiver.files = {"result.txt" => "results"}
      archiver.enabling_states = [Build::Successful.new]
      
      scm = RSCM::Subversion.new
      scm.url = RSCM::PathConverter.filepath_to_nativeurl(central_repo)
      copy_command = family == "mswin32" ? "copy" : "cp"
      project = Project.create(
        :name => "Test", 
        :scm => scm, 
        :publishers => [archiver], 
        :build_command => "#{copy_command} input.txt result.txt",
        :local_build => true
      )
      project.reload
      #project.build_executors << BuildExecutor.create(:is_master => true)
      assert_equal(1, project.build_executors.length)
      assert(project.build_executors[0].is_master)

      assert_equal(::DamageControl::Publisher::ArtifactArchiver, project.publishers[0].class)
      
      # create svn repository
      scm.create_central

      # nothing should have happened yet
      daemon.handle_all_projects_once
      assert_equal(0, project.revisions.length)
      
      # check out, change file and commit
      scm.checkout_dir = checkout_dir
      scm.checkout
      create_file(checkout_dir + "/input.txt", "This is a test")
      scm.add("input.txt")
      scm.commit("This is just a test")
      
      # this should execute a build
      daemon.handle_all_projects_once

      log.rewind
      #puts log.read

      # check build executed
      project.reload
      assert_equal(1, project.revisions.length)
      assert_equal(1, project.latest_revision.builds.length)
      build = project.latest_revision.builds[0]
      stderr = File.open(build.stderr_file).read
      stdout = File.open(build.stdout_file).read
      assert(build.successful?, "STDERR:#{stderr}\nSTDOUT:#{stdout}")
      assert_equal("This is a test", File.open(Artifact::ARTIFACT_DIR + "/results/result.txt").read)
    end

  end
end