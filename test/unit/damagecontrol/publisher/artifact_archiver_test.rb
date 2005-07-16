require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class ArtifactArchiverTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions

      def test_should_archive_in_project_directory
        Directory.delete_all
        Artifact.delete_all
        
        # prepare a 'built' file
        artifact_dir = "#{@project_1.working_copy_dir}/pkg"
        FileUtils.rm_rf(artifact_dir) if File.exist?(artifact_dir)
        FileUtils.mkdir_p(artifact_dir)
        File.open("#{artifact_dir}/dummy.gem", "w") do |io|
          io.puts("blah")
        end

        expected_archived_file = DAMAGECONTROL_HOME + '/artifacts/dummy.gem'
        File.rm(expected_archived_file) if File.exist?(expected_archived_file)
        
        aa = ArtifactArchiver.new
        aa.files = {
          "pkg/*.gem" => "gems"
        }
        assert_equal([], Directory.root.files)
        aa.publish(@build_1)
        assert(File.exist?(expected_archived_file), "Should exist: #{expected_archived_file}")
        assert_equal(1, Directory.root.files.length)
        artifact = @build_1.artifacts[0]
        assert_equal(["gems", "dummy.gem"], artifact.path)
        artifact.open do |io|
          assert_equal("blah\n", io.read)
        end
      end
    end
  end
end