require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class ArtifactArchiverTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions

      def test_should_archive_in_project_directory
        artifact_dir = "#{@project_1.working_copy_dir}/pkg"
        FileUtils.rmdir(artifact_dir) if File.exist?(artifact_dir)
        FileUtils.mkdir_p(artifact_dir)
        File.open("#{artifact_dir}/dummy.gem", "w") do |io|
          io.puts("blah")
        end

        expected_archived_file = DAMAGECONTROL_HOME + '/artifacts/gems/dummy.gem'
        File.rm(expected_archived_file) if File.exist?(expected_archived_file)
        
        aa = ArtifactArchiver.new
        aa.files = {
          "pkg/*.gem" => "gems"
        }
        aa.publish(@build_1)
        assert(File.exist?(expected_archived_file), "Should exist: #{expected_archived_file}")
      end
    end
  end
end