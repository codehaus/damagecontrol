module DamageControl
  class ScmPoller
    cattr_accessor :logger
    
    # Default time to wait for scm to be quiet (applies to non-transactional scms only)
    DEFAULT_QUIET_PERIOD = 15 unless defined? DEFAULT_QUIET_PERIOD

    # Polls all registered projects for new revisions since last time and persists them
    # to the database.
    def poll_all_projects
      ::Project.find(:all).each do |project|
        begin
          revisions = poll_new_revisions(project)
          if(revisions && !revisions.empty?)
            # persist revisions to the database
            persist_revisions(project, revisions)
            persist_build_for_lates_revision(project)
          end
        rescue => e
          if(logger)
            logger.error "Error polling #{project.name}"
            logger.error  e.message
            logger.error "  " + e.backtrace.join("  \n")
          end
        end
      end
    end

    # Stores revisions in the database 
    def persist_revisions(project, revisions)
      revisions.each do |revision|
        # We're not doing:
        #   project.revisions.create(revision)
        # because of the way Revision.create is implemented (overridden).
        # TODO: chop up in smaller txns! This will reduce the likelyhood of collision with web ui
        revision.project_id = project.id
        Revision.create(revision)
      end
    end
    
    # Persists a new build (to be picked up by a BuildExecutor)
    # for the last revision. Done separately since the RSCM adapter
    # may not be implemented to return revisions in the right order.
    # This method picks the latest revision.
    # TODO: deprecated by BuildDaemon
    def persist_build_for_lates_revision(project)
      # TODO: optimize this query.
      logger.info "Requesting build for #{project.name}" if logger
      last_revision = project.latest_revision
      last_revision.builds.create(:reason => Build::SCM_POLLED)
      logger.info "Requested build for #{project.name}" if logger
    end

    def poll_new_revisions(project)
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
      from = project.start_time
      if(latest_revision)
        from = latest_revision.identifier
        logger.info "Latest revision for #{project.name}'s #{scm.name} "+
          "was #{from}" if logger
      else
        logger.info "Latest revision for #{project.name}'s #{scm.name} is " +
          "not known. Using project start time: #{from}" if logger
      end

      logger.info "Polling revisions for #{project.name}'s #{scm.name} " +
        "after #{from} (#{from.class.name})" if logger
      
      revisions = scm.revisions(from)
      if(revisions.empty?)
        logger.info "No revisions for #{project.name}'s #{scm.name} after " +
          "#{from}" if logger
      else
        logger.info "There were #{revisions.length} new revision(s) in " +
          "#{project.name}'s #{scm.name} after #{from}" if logger
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
            "#{project.name}'s SCM (#{scm.name}) is not transactional." if logger
          
          sleep(quiet_period)
          previous_revisions = revisions
          revisions = scm.revisions(from)
          commit_in_progress = revisions != previous_revisions
          if(commit_in_progress)
            logger.info "Commit still in progress in #{project.name}'s #{scm.name}." if logger
          end
        end
        logger.info "Quiet period elapsed for #{project.name}." if logger
      end
      return revisions
    end
  end
end
