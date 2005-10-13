module DamageControl
  
  class ScmPoller
    cattr_accessor :logger
    
    # Default time to wait for scm to be quiet (applies to non-transactional scms only)
    DEFAULT_QUIET_PERIOD = 15 unless defined? DEFAULT_QUIET_PERIOD
    
    # Polls for new revisions in the SCM and persists them.
    # The latest revision is returned.
    def poll_and_persist_new_revisions(project)
      if(project.scm)
        rscm_revisions = project.scm.poll_new_revisions(project.latest_revision)
        persist_revisions(project, rscm_revisions) unless rscm_revisions.length == 0
      end
    end
    
    # Stores revisions in the database and returns the latest persisted revision.
    def persist_revisions(project, rscm_revisions)
      rev = nil
      logger.info "Persisting #{rscm_revisions.length} new revisions for #{project.name}" if logger
      position = project.revisions.length
      
      # There may be a lot of inserts. Doing it in one txn will speed it up
      Revision.transaction do
        rscm_revisions.each do |rscm_revision|
          # TODO: chop up in bigger txns! This will reduce the likelihood of collision with web ui
          rscm_revision.project_id = project.id
          rscm_revision.position = position
          position += 1

          # This will go on the web and scrape issue summaries. Might take a little while....
          begin
            # TODO: parse patois messages here too.
            rscm_revision.message = project.tracker.markup(rscm_revision.message) if project.tracker
          rescue => e
            logger.warn "Error marking up issue summaries for #{project.name}: #{e.message}" if logger
          end
          # We're not doing:
          #   project.revisions.create(revision)
          # because of the way Revision.create is implemented (overridden).
          rev = Revision.create(rscm_revision)
        end
      end
      rev
    end
    
  end
end
