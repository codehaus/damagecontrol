require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class ArtifactArchiverTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions, :artifacts

      def test_should_archive_in_project_directory_and_create_artifact_record
        artifact_dir = "#{projects(:project_1).working_copy_dir}/pkg"
        FileUtils.rm_rf(artifact_dir) if File.exist?(artifact_dir)
        FileUtils.mkdir_p(artifact_dir)
        File.open("#{artifact_dir}/dummy.gem", "w") do |io|
          io.puts("blah")
        end

        expected_archived_file = DC_DATA_DIR + '/artifacts/gems/dummy.gem'
        File.rm(expected_archived_file) if File.exist?(expected_archived_file)

        aa = ArtifactArchiver.new
        aa.files = {
          "pkg/*.gem" => "gems"
        }
        aa.publish(builds(:build_1))
        assert(File.exist?(expected_archived_file), "Should exist: #{expected_archived_file}")
        
        # we want a record too
        assert_equal(1, builds(:build_1).artifacts.length)
        artifact = builds(:build_1).artifacts[0]
        assert_equal("gems/dummy.gem", artifact.relative_path)
      end
    end
  end
end