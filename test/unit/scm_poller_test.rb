require File.dirname(__FILE__) + '/../test_helper'

class ScmPollerTest < Test::Unit::TestCase
  fixtures :projects

  def test_should_persist_revision_files
    rscm_file = RSCM::RevisionFile.new
    rscm_file.path = "foo/bar"
  end
end
