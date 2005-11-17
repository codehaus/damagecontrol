class RevisionFile < ActiveRecord::Base
  belongs_to :revision
  
  def timepoint
    self[:timepoint] || revision.timepoint
  end

  # It's a bit hackish to embed view info in the model :-(
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

# Adaptation to make it possible to create an AR RevisionFile
# from an RSCM one
class RSCM::RevisionFile
  # Temporary attributes used while persisting and indexing
  attr_accessor :id
  attr_accessor :revision_id
  
  def stringify_keys!
  end
  
  def reject
    {
      "revision_id" => revision_id,
      "status" => status,
      "path" => path,
      "previous_native_revision_identifier" => previous_native_revision_identifier,
      "native_revision_identifier" => native_revision_identifier,
      "timepoint" => time
    }
  end
end