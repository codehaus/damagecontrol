require File.dirname(__FILE__) + '/../test_helper'

class ScmPollerTest < Test::Unit::TestCase
  fixtures :projects

  def Xtest_should_get_revisions_from_start_time_if_last_change_time_unknown_on_poll
    @project.scm = new_mock
    #@p.scm.__setup(:name) {"MockSCM"}
    @p.poll(0) do |cs|
      assert_equal(revisions, cs)
    end
  end
  
  def test_should_persist_revision_files
    rscm_file = RSCM::RevisionFile.new
    rscm_file.path = "foo/bar"
  end
end
