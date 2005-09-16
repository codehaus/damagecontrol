require 'pathname'

# An Artifact is a file created during a build. Artifacts are archived
# so they can be retrieved later, typically downloaded over HTTP.
class Artifact < ActiveRecord::Base
  
  ARTIFACT_DIR = "#{DC_DATA_DIR}/artifacts"
  FileUtils.mkdir_p(ARTIFACT_DIR) unless File.exist?(ARTIFACT_DIR)

  # The file represented by this Artifact, as a Pathname object.
  def file
    Pathname.new(file_name = ARTIFACT_DIR + "/" + relative_path)
  end
  
end
