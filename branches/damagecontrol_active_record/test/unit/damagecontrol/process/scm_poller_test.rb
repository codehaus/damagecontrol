require File.dirname(__FILE__) + '/../../../test_helper'
require 'rscm/mockit'
require 'stringio'

module DamageControl
  module Process
    class ScmPollerTest < Test::Unit::TestCase

      def Xtest_should_allow_concurrent_update
        rc = 5
        fc = 4
        rsc = 10

        # Create some big data to persist
        rscm_revisions = []
        (1..rc).each do |r|
          rscm_revision = RSCM::Revision.new
          rscm_revision.time = Time.now.utc
          rscm_revision.identifier = 999
          rscm_revision.developer = "aslak"
          rscm_revision.message = File.open(__FILE__).read # biggish

          t = Time.now.utc
          (1..fc).each do |f|
            rscm_file = RSCM::RevisionFile.new(
              "some/path/#{f}",
              RSCM::RevisionFile.ADDED,
              "aslak",
              rscm_revision.message,
              f,
              t + 1
            )
            rscm_revision << rscm_file
          end
          rscm_revisions << rscm_revision
        end
        rscm_revisions = RSCM::Revisions.new(rscm_revisions)


        poller = ScmPoller.new
        threads = []
        n = Project.find(:all).size
        (1..rsc).each do |i|
          threads << Thread.new do
            p = Project.create(:name => "concurrent_project_#{n+i}")
            poller.persist_revisions(p, rscm_revisions)
          end
        end
        threads.each{|t| t.join}
        assert_equal(threads.length + 3, Project.find(:all).length)
        assert_equal(rc*fc*rsc + 6, RevisionFile.find(:all).length)
      end

      def test_should_use_custom_revision_label_if_specified_for_project
        p = Project.create(:name => "toto", :initial_revision_label => 234)

        rscm_revision_1 = RSCM::Revision.new
        rscm_revision_2 = RSCM::Revision.new

        poller = ScmPoller.new
        revisions = poller.persist_revisions(p, [rscm_revision_1, rscm_revision_2])
        assert_equal(1, revisions[0].position)
        assert_equal(235, revisions[0].label)
        assert_equal(2, revisions[1].position)
        assert_equal(236, revisions[1].label)
      end

      def test_should_request_build_when_change_committed
        log = StringIO.new

        ScmPoller.logger = Logger.new(log)
        scm_poller = ScmPoller.new

        # create svn repository
        scm = RSCM::Subversion.new
        scm.url = RSCM::PathConverter.filepath_to_nativeurl(central_repo)
        scm.create_central

        project = Project.create(:name => "polling test", :scm => scm)
        project.reload

        # nothing should have happened yet
        scm_poller.poll_if_needed(project)
        assert_equal(0, project.revisions.length)

        # check out, change file and commit
        scm.checkout_dir = checkout_dir
        scm.checkout
        create_file(checkout_dir + "/input.txt", "This is a test")
        scm.add("input.txt")
        scm.commit("This is just a test")

        # this should detect a new revision and request a build
        scm_poller.poll_if_needed(project)
        log.rewind
        #puts log.read
        project.reload
        assert_equal(1, project.revisions.length)
        assert_equal(1, project.latest_revision.builds.length)
        build = project.latest_revision.builds[0]
        assert_equal(Build::Requested, build.state.class)
      end

    private

      def new_dir(dir)
        FileUtils.rm_r(dir) if File.exist?(dir)
        FileUtils.mkdir_p(dir)
        dir
      end

      def central_repo
        @repo_dir ||= new_dir("#{DC_DATA_DIR}/scm_poller_test/central")
      end

      def checkout_dir
        @checkout_dir ||= new_dir("#{DC_DATA_DIR}/scm_poller_test/local")
      end

      def create_file(file, content)
        File.open(file, "w") do |io|
          io.write(content)
        end
      end

    end
  end
end