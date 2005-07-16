require 'file_methods'

# An Artifact is a file created during a build. Artifacts are archived
# so they can be retrieved later, typically downloaded over HTTP.
class Artifact < ActiveRecord::Base
  belongs_to :parent, :class_name => "Directory"
  
  include FileMethods

  ROOT_DIR = "#{DAMAGECONTROL_HOME}/artifacts"
  FileUtils.mkdir_p(ROOT_DIR) unless File.exist?(ROOT_DIR)

  # Returns or yields (if a block is passed) an IO object
  # where the artifact data can be read from.  
  def open
    file_name = ROOT_DIR + "/" + file_reference
    if(block_given?)
      File.open(file_name) do |io|
        yield io
      end
    else
      File.open(file_name)
    end
  end
  
  # Our children, which is [] since we're a leaf
  def files
    []
  end
end
