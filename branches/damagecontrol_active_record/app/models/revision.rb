class Revision < ActiveRecord::Base
  ActiveRecord::Base.default_timezone = :utc
  
  belongs_to :project
  has_many :revision_files
  has_many :builds
  
  def self.create(rscm_revision)
    revision = super(rscm_revision)

    rscm_revision.each do |rscm_file|
      revision.revision_files.create(rscm_file)
    end
    
    revision
  end

  # Syncs the working copy of the project with this revision.
  def sync_working_copy
    project.scm.checkout(identifier) if project.scm
  end

end

# Adaptation to make it possible to create an AR Revision
# from an RSCM one
class RSCM::Revision
  attr_accessor :project_id
  
  def stringify_keys!
  end
  
  def reject
    # we could have used reflection, but this is just as easy!
    {
      "project_id" => project_id,
      "identifier" => identifier,
      "developer" => developer,
      "message" => message,
      "timepoint" => time
    }
  end
end