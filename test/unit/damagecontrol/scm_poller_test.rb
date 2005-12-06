require File.dirname(__FILE__) + '/../../test_helper'
require 'rscm/mockit'
require 'stringio'

module DamageControl
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
    
    class FakeScm
      attr_writer :checkout_dir
      attr_writer :enabled
      
      @@contents = {
        "contains/juice.rb" => "what juice do you like?",
        "contains/milk.rb" => "is milk good for dogs?",
        "contains/wine.rb" => "should i feed my husband wine?"
      }
      
      def open(revision_file, &block)
        yield StringIO.new(@@contents[revision_file.path])
      end
    end
    
    def test_should_index_files
      return
      scm = FakeScm.new
      
      p = Project.create(:name => "pp", :scm => scm)
      
      r = RSCM::Revision.new
      r << RSCM::RevisionFile.new("contains/juice.rb", RSCM::RevisionFile::ADDED)
      r << RSCM::RevisionFile.new("contains/milk.rb", RSCM::RevisionFile::ADDED)
      r << RSCM::RevisionFile.new("contains/wine.rb", RSCM::RevisionFile::ADDED)

      revisions = ScmPoller.new.persist_revisions(p, [r])
      Revision.index!(revisions)
      
      files = RevisionFile.find_by_contents("milk")
      
      assert_equal 1, files.length
      assert_equal "contains/milk.rb", files[0].path
    end

  end

end