require File.dirname(__FILE__) + '/../test_helper'

class ArtifactTest < Test::Unit::TestCase
  fixtures :artifacts

  def test_should_store_and_retrieve_real_file
    # this would normally be done by the archiver
    real_file_name = Artifact::ARTIFACT_DIR + "/artifact.txt"
    File.open(real_file_name, "w") do |io|
      io.puts("yo")
    end
    
    artifact = Artifact.create(:relative_path => "artifact.txt")
    artifact.file.open do |io|
      assert_equal("yo\n", io.read)
    end

    assert_equal("yo\n", artifact.file.open.read)
  end
end
