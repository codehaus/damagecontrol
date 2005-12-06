module DamageControl
  
  # Polls SCMs for new revisions and persists them in the database. Also updates the Ferret
  # index, which is the backbone for searching.
  class ScmPoller

    cattr_accessor :logger

    # Polls for new revisions in the SCM and persists them.
    # The latest revision is returned.
    def poll_and_persist_new_revisions(project)
      if(project.scm)
        project.prepare_scm
        rscm_revisions = project.scm.poll_new_revisions(project.latest_revision)
        revisions = nil
        unless rscm_revisions.length == 0
          revisions = persist_revisions(project, rscm_revisions)
          Revision.index!(revisions)
        end
        revisions ? revisions[-1] : nil
      end
    end

    # Stores revisions in the database and returns the persisted revisions.
    def persist_revisions(project, rscm_revisions)
      logger.info "Persisting #{rscm_revisions.length} new revisions for #{project.name}" if logger
      position = project.revisions.length
      
      # There may be a lot of inserts. Doing it in one txn will speed it up
      Revision.transaction do
        rscm_revisions.collect do |rscm_revision|
          position += 1

          # This will go on the web and scrape issue summaries. Might take a little while....
          # TODO: Do this on demand in an ajax call?
          begin
            # TODO: parse patois messages here too.
            rscm_revision.message = project.tracker.markup(rscm_revision.message) if project.tracker
          rescue => e
            logger.warn "Error marking up issue summaries for #{project.name}: #{e.message}" if logger
          end
          # We're not doing:
          #   project.revisions.create(revision)
          # because of the way Revision.create is implemented (overridden).
          Revision.create_from_rscm_revision(project, rscm_revision, position)
        end
      end
    end
    
  end
end
