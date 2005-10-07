module DamageControl
  
  class ScmPoller
    cattr_accessor :logger
    
    # Default time to wait for scm to be quiet (applies to non-transactional scms only)
    DEFAULT_QUIET_PERIOD = 15 unless defined? DEFAULT_QUIET_PERIOD
    
    # Polls for new revisions in the SCM and persists them.
    # The latest revision is returned.
    def poll_and_persist_new_revisions(project)
      rscm_revisions = poll_new_revisions(project)
      persist_revisions(project, rscm_revisions) unless rscm_revisions.length == 0
    end
    
    # Stores revisions in the database and returns the latest persisted revision.
    def persist_revisions(project, rscm_revisions)
      rev = nil
      logger.info "Persisting #{rscm_revisions.length} new revisions for #{project.name}" if logger
      position = project.revisions.length
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
    
    # Polls new revisions for +project+ since last persisted revision,
    # or if no revision is persisted yet, polls since 'now' - +seconds_before_now+.
    # If no revisions are found AND the poll was using +seconds_before_now+
    # (i.e. it's the first poll, and no revisions were found),
    # calls itself recursively with twice the +seconds_before_now+.
    # This happens until revisions are found, ot until the +seconds_before_now+
    # Exceeds 32 weeks, which means it's probably not worth looking further in
    # the past, the project is either completely idle or not yet active.
    def poll_new_revisions(project, seconds_before_now=2.weeks)
      scm = project.scm
      if(!scm)
        logger.info "Not polling #{project.name} it doesn't seem to have a proper scm configuration" if logger
        return []
      end
      if(!scm.central_exists?)
        logger.info "Not polling #{project.name} since its central scm repo doesn't seem to exist" if logger
        return []
      end
      
      latest_revision = project.latest_revision
      
      # Default value for start time (in case there are no detected revisions yet)
      from = seconds_before_now.ago
      if(latest_revision)
        from = latest_revision.identifier
        logger.info "Latest revision for #{project.name}'s #{scm.visual_name} "+
          "was #{from}" if logger
      else
        if(from < 32.weeks.ago)
          logger.info "Checked for revisions as far back as 32 weeks ago (#{32.weeks.ago}). There were none, so we give up." if logger
          return []
        else
          logger.info "Latest revision for #{project.name}'s #{scm.visual_name} is " +
            "not known. Checking for revisions since: #{from}" if logger
        end
      end

      logger.info "Polling revisions for #{project.name}'s #{scm.visual_name} " +
        "after #{from} (#{from.class.name})" if logger
      
      revisions = scm.revisions(from)
      if(revisions.empty?)
        logger.info "No new revisions for #{project.name}'s #{scm.visual_name} after " +
          "#{from}" if logger
        unless(latest_revision)
          double_seconds_before_now = 2*seconds_before_now
          logger.info "We still haven't determined when the last revision in #{project.name}'s #{scm.visual_name} occurred, " +
            "so we'll check since #{double_seconds_before_now.ago}" if logger
          return poll_new_revisions(project, double_seconds_before_now)
        end
      else
        logger.info "There were #{revisions.length} new revision(s) in " +
          "#{project.name}'s #{scm.visual_name} after #{from}" if logger
      end
      if(!revisions.empty? && !scm.transactional?)
        # We're dealing with a non-transactional SCM (like CVS/StarTeam/ClearCase,
        # unlike Subversion/Monotone). Sleep a little, get the revisions again.
        # When the revisions are not changing, we can consider the last commit done
        # and the quiet period elapsed. This is not 100% failsafe, but will work
        # under most circumstances. In the worst case, we'll miss some files in
        # the revisions for really slow commits, but they will be part of the next 
        # revision (on next poll).
        commit_in_progress = true
        quiet_period = project.quiet_period || DEFAULT_QUIET_PERIOD
        while(commit_in_progress)
          logger.info "Sleeping for #{quiet_period} seconds because " + 
            "#{project.name}'s SCM (#{scm.visual_name}) is not transactional." if logger
          
          sleep(quiet_period)
          previous_revisions = revisions
          revisions = scm.revisions(from)
          commit_in_progress = revisions != previous_revisions
          if(commit_in_progress)
            logger.info "Commit still in progress in #{project.name}'s #{scm.visual_name}." if logger
          end
        end
        logger.info "Quiet period elapsed for #{project.name}." if logger
      end
      return revisions
    end
  end
end
