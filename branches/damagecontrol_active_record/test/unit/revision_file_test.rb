require File.dirname(__FILE__) + '/../test_helper'

class RevisionFileTest < Test::Unit::TestCase
  fixtures :revisions, :revision_files

  def test_should_have_properties
    assert_equal("MODIFIED", revision_files(:revision_file_1_1).status)
    assert_equal("three/blind/mice.rb", revision_files(:revision_file_1_1).path)
    assert_equal("1.4.4", revision_files(:revision_file_1_1).previous_native_revision_identifier)
    assert_equal("1.4.5", revision_files(:revision_file_1_1).native_revision_identifier)
    assert_equal(Time.utc(1971, 2, 28, 23, 45, 1), revision_files(:revision_file_1_1).timepoint)
    assert_equal(revisions(:revision_1), revision_files(:revision_file_1_1).revision)
  end
  
  def test_should_get_time_from_revision_if_nil
    assert_equal(Time.utc(1971, 2, 28, 23, 45, 0), revision_files(:revision_file_1_2).timepoint)
  end

  def test_should_persist_rscm_revision_files
    assert_equal([], revisions(:revision_2).revision_files)

    rscm_file = RSCM::RevisionFile.new
    rscm_file.revision_id = 2
    rscm_file.status = RSCM::RevisionFile::DELETED
    rscm_file.path = "foo/bar"
    rscm_file.previous_native_revision_identifier = "2.3.4"
    rscm_file.native_revision_identifier = "2.3.5"
    rscm_file.time = Time.utc(1971, 2, 28, 23, 45, 2)
    
    RevisionFile.create(rscm_file)

    ar_file = revisions(:revision_2).revision_files(true)[0]
    assert_equal(revisions(:revision_2), ar_file.revision)
    assert_equal("DELETED", ar_file.status)
    assert_equal("foo/bar", ar_file.path)
    assert_equal("2.3.4", ar_file.previous_native_revision_identifier)
    assert_equal("2.3.5", ar_file.native_revision_identifier)
    assert_equal(Time.utc(1971, 2, 28, 23, 45, 2), ar_file.timepoint)
  end
end
