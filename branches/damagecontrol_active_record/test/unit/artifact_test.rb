require File.dirname(__FILE__) + '/../test_helper'

class ArtifactTest < Test::Unit::TestCase
  fixtures :artifacts

  def setup
    @artifact = Artifact.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Artifact,  @artifact
  end
end
