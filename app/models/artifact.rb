require 'pathname'

# An Artifact is a file created during a build. Artifacts are archived
# so they can be retrieved later, typically downloaded over HTTP.
class Artifact < ActiveRecord::Base
  
  ROOT_DIR = "#{DAMAGECONTROL_HOME}/artifacts"
  FileUtils.mkdir_p(ROOT_DIR) unless File.exist?(ROOT_DIR)

  # The file represented by this Artifact, as a Pathname object.
  def file
    Pathname.new(file_name = ROOT_DIR + "/" + relative_path)
  end
  
end
