class Revision < ActiveRecord::Base
  cattr_accessor :logger
  ActiveRecord::Base.default_timezone = :utc
  
  belongs_to :project
  has_many :revision_files
  has_many :builds
  # identifier can be String, Numeric or Time, so we YAML it to the database.
  # we hahave to fool AR to do this by wrapping it in an array - serialize doesn't work
  def identifier=(i)
    self[:identifier] = YAML::dump([i])
  end
  def identifier
     (YAML::load(self[:identifier]))[0]
  end
  
  def self.create(rscm_revision)
    revision = super(rscm_revision)

    rscm_revision.each do |rscm_file|
      revision.revision_files.create(rscm_file)
    end
    
    revision
  end

  # Syncs the working copy of the project with this revision.
  def sync_working_copy
    logger.info "Syncing working copy for #{project.name} with revision #{identifier} ..." if logger
    project.scm.checkout(identifier) if project.scm
    logger.info "Done Syncing working copy for #{project.name} with revision #{identifier}" if logger
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