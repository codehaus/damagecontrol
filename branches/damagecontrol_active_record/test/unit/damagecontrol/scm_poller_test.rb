require File.dirname(__FILE__) + '/../../test_helper'

module DamageControl
  class ScmPollerTest < Test::Unit::TestCase
    fixtures :projects, :revisions, :builds

    def test_should_allow_concurrent_update
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
      (1..rsc).each do |i|
        threads << Thread.new do
          p = Project.create(:name => "concurrent_project_#{i}")
          poller.persist_revisions(p, rscm_revisions)
        end
      end
      threads.each{|t| t.join}
      assert_equal(threads.length + 3, Project.find(:all).length)
      assert_equal(rc*fc*rsc + 6, RevisionFile.find(:all).length)
    end
  end
end