require File.dirname(__FILE__) + '/../test_helper'

class ArtifactTest < Test::Unit::TestCase
  fixtures :artifacts, :directories

  def test_should_be_under_directory
    jar = Artifact.create(:name => "picocontainer-1.3.4567.jar", :directory_id => @local.id)

    assert_equal(@local, jar.parent)
    assert_equal(["usr", "local", "picocontainer-1.3.4567.jar"], jar.path)
  end

  def test_should_store_and_retrieve_real_file
    # this would normally be done by the archiver
    real_file_name = Artifact::ROOT_DIR + "/artifact.txt"
    File.open(real_file_name, "w") do |io|
      io.puts("yo")
    end
    
    artifact = Artifact.create(:name => "something.else", :directory_id => @usr.id, :file_reference => "artifact.txt")
    artifact.open do |io|
      assert_equal("yo\n", io.read)
    end

    assert_equal("yo\n", artifact.open.read)
  end
end
