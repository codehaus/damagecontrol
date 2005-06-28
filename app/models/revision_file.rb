class RevisionFile < ActiveRecord::Base
  ActiveRecord::Base.default_timezone = :utc

  belongs_to :revision
  
  def timepoint
    self[:timepoint] || revision.timepoint
  end
end

# Adaptation to make it possible to create an AR RevisionFile
# from an RSCM one
class RSCM::RevisionFile
  attr_accessor :revision_id
  
  def stringify_keys!
  end
  
  def reject
    # we could have used reflection, but this is just as easy!
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