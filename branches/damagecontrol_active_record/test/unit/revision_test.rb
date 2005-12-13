require File.dirname(__FILE__) + '/../test_helper'
require 'rscm/mockit'

class RevisionTest < Test::Unit::TestCase

  def test_should_have_builds
    assert_equal([builds(:build_1)], revisions(:revision_1).builds)
  end

  def test_should_have_scm_files
    files = revisions(:revision_1).scm_files
    assert_equal 1, files.size
    assert_equal "README", files[0].path
    assert_equal "1.4.5", files[0].native_revision_identifier
  end

  def test_should_have_properties
    assert_equal(1, revisions(:revision_1).identifier)
    assert_equal("aslak", revisions(:revision_1).developer)
    assert_equal("fixed a bug", revisions(:revision_1).message)
    assert_equal(Time.utc(1971, 2, 28, 23, 45, 0), revisions(:revision_1).timepoint)
    assert_equal(projects(:project_1), revisions(:revision_1).project)
  end

  def test_should_persist_rscm_revisions
    assert_equal([revisions(:revision_4)], projects(:project_2).revisions)

    rscm_revision = RSCM::Revision.new
    rscm_revision.identifier = "qwerty"
    rscm_revision.developer = "hellesoy"
    rscm_revision.message = "yippee"
    rscm_revision.time = Time.utc(1971, 2, 28, 23, 45, 3)
    
    rscm_file_1 = RSCM::RevisionFile.new
    rscm_file_1.path = "here/i/am"
    rscm_revision << rscm_file_1
    rscm_file_2 = RSCM::RevisionFile.new
    rscm_file_2.path = "here/i/go"
    rscm_revision << rscm_file_2

    Revision.create_from_rscm_revision(projects(:project_2), rscm_revision, 1)
    
    ar_revision = projects(:project_2).revisions(true)[0]
    assert_equal(projects(:project_2), ar_revision.project)
    assert_equal("qwerty", ar_revision.identifier)
    assert_equal("hellesoy", ar_revision.developer)
    assert_equal("yippee", ar_revision.message)
    assert_equal(Time.utc(1971, 2, 28, 23, 45, 3), ar_revision.timepoint)
    
    assert_equal("here/i/am", ar_revision.scm_files[0].path)
    assert_equal("here/i/go", ar_revision.scm_files[1].path)
  end

  def test_should_request_build_for_each_build_executor_and_persist_build_number
    assert_equal(0, revisions(:slave_revision).builds.size)
    builds = revisions(:slave_revision).request_builds(Build::SCM_POLLED)
    assert_equal(2, revisions(:slave_revision).builds(true).size)
    assert_equal(Build::SCM_POLLED, revisions(:slave_revision).builds[0].reason)

    assert_equal(1, builds[0].number)
    assert_equal(2, builds[1].number)
  end

  def test_should_sync_projects_working_copy_and_zip_it
    scm = new_mock
    scm.__expect(:checkout) do |identifier|
      assert_equal(1, identifier)
    end
    scm.__setup(:checkout_dir) do
      "checkout_dir"
    end
    revisions(:revision_1).project.scm = scm

    zipper = new_mock
#    zipper.__expect :zip do |dirname, zipfile_name, exclude_patterns|
#      assert_equal "checkout_dir", dirname
#      assert_equal File.expand_path(revisions(:revision_1).project.zip_dir + "/1.zip"), File.expand_path(zipfile_name)
#      # TODO assert_equal ["build/*", "*.log"], exclude_patterns
#      assert_equal [], exclude_patterns
#    end
    
    revisions(:revision_1).sync_working_copy!(true, zipper)
  end
  
  def test_should_persist_identifier_as_time
    now = Time.now.utc
    rscm_revision = RSCM::Revision.new
    rscm_revision.identifier = now
    revision = Revision.create_from_rscm_revision(projects(:project_1), rscm_revision, 1)
    revision.reload
    assert_equal(now, revision.identifier)
  end

  def test_should_persist_identifier_as_string
    rscm_revision = RSCM::Revision.new
    rscm_revision.identifier = "koko"
    revision = Revision.create_from_rscm_revision(projects(:project_1), rscm_revision, 1)
    revision.reload
    assert_equal("koko", revision.identifier)
  end

  def test_should_persist_identifier_as_int
    rscm_revision = RSCM::Revision.new
    rscm_revision.identifier = 999
    revision = Revision.create_from_rscm_revision(projects(:project_1), rscm_revision, 1)
    revision.reload
    assert_equal(999, revision.identifier)
  end
  
end
