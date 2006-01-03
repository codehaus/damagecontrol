# Represents a virtual file system mirroring the historic structure 
# (but not the contents) of the real SCM. Serves as a model for the 
# SCM browser.
class ScmFile < ActiveRecord::Base
  
  # Finds the revisions for this file (revisions where the file changed).
  #
  #   scm_file.revisions           # => All revisions
  #   scm_file.revisions.latest(r) # => The latest revision prior to or equal to r
  #   scm_file.revisions.latest    # => The latest revision
  has_and_belongs_to_many :revisions, :order => "identifier" do
    def latest(identifier=nil)
      identifier ||= "ZZZZZZZZZZZ"
      # identifiers are stored as YAML in the database since they can be of different Ruby types
      find(:first, :order => "identifier DESC", :conditions => ["identifier <= ?", [identifier].to_yaml])
    end
  end

  belongs_to :project
  acts_as_tree :order => "path", :counter_cache => true

  # Ensures that the parent directory exists
  def before_create #:nodoc:
    ensure_parent_exists!
  end
  
  def ensure_parent_exists! #:nodoc:
    unless(path == "")
      parent_path = path.split("/")[0..-2].join("/")
      self.parent = self.class.find_or_create_by_directory_and_path_and_project_id(true, parent_path, self.project_id)
    end
  end

  def basename
    File.basename(path)
  end

  DESCRIPTIONS = {
    RSCM::RevisionFile::ADDED => "New file",
    RSCM::RevisionFile::DELETED => "Deleted file",
    RSCM::RevisionFile::MODIFIED => "Modified file",
    RSCM::RevisionFile::MOVED => "Moved file"
  } unless defined? DESCRIPTIONS

  def status_description
    DESCRIPTIONS[status]
  end

end
