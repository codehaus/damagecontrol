# Represents a virtual file system mirroring the historic structure 
# (but not the contents) of the real SCM. Serves as a model for the 
# SCM browser.
class ScmFile < ActiveRecord::Base
  has_and_belongs_to_many :revisions
  belongs_to :project
  acts_as_tree :order => "path", :counter_cache => true

  # Ensures that the parent directory exists
  def before_create #:nodoc:
    parent_path = path.split("/")[0..-2].join("/")
    unless(parent_path == "")
      self.parent = self.class.find_or_create_by_directory_and_path_and_project_id(true, parent_path, self.project_id)
    end
  end

  # Returns/yields an IO containing the contents of this file, using the +scm+ this
  # file lives in. Important: This will only work if this instance was retrieved via
  # Revision#scm_files
  def open(&block)
    project.scm.open(self, &block)
  end

  # TODO: Move to view - It's a bit hackish to embed view info in the model :-(
  ICONS = {
    RSCM::RevisionFile::ADDED => "document_new",
    RSCM::RevisionFile::DELETED => "document_delete",
    RSCM::RevisionFile::MODIFIED => "document_edit",
    RSCM::RevisionFile::MOVED => "document_exchange"
  } unless defined? ICONS

  DESCRIPTIONS = {
    RSCM::RevisionFile::ADDED => "New file",
    RSCM::RevisionFile::DELETED => "Deleted file",
    RSCM::RevisionFile::MODIFIED => "Modified file",
    RSCM::RevisionFile::MOVED => "Moved file"
  } unless defined? DESCRIPTIONS

  def icon
    ICONS[status]
  end

  def status_description
    DESCRIPTIONS[status]
  end

end
