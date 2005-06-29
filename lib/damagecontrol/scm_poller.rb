module DamageControl
  class ScmPoller
    # default time to wait for scm to be quiet (applies to non-transactional scms only)
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
          end
        rescue => e
          Log.error "Error polling #{project.name}"
          Log.error  e.message
          Log.error "  " + e.backtrace.join("  \n")
        end
      end
    end
    
    def persist_revisions(project, revisions)
      Log.info "Persisting #{revisions.length} revision(s) for #{project.name}"
      revisions.each do |revision|
        # We're not doing:
        #   project.revisions.create(revision)
        # because of the way Revision.create is implemented (overridden).
        revision.project_id = project.id
        Revision.create(revision)
      end
      Log.info "Done persisting #{revisions.length} revision(s) for #{project.name}"
    end
    
    def poll_new_revisions(project)
      scm = project.scm
      if(scm.central_exists?)
        latest_revision = project.revisions[-1]
        from = latest_revision ? latest_revision.identifier : project.start_time

        revisions = scm.revisions(from)
        if(revisions.empty?)
          Log.info "No revisions for #{project.name}'s #{scm.name} after #{from}"
        else
          Log.info "There was #{revisions.length} new revision(s) for #{project.name}'s #{scm.name} after #{from}"
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
            Log.info "Sleeping for #{quiet_period} seconds because #{project.name}'s SCM (#{@scm.name}) is not transactional."
            sleep(quiet_period)
            previous_revisions = revisions
            revisions = scm.revisions(from)
            commit_in_progress = revisions != previous_revisions
            if(commit_in_progress)
              Log.info "Commit still in progress for #{project.name}."
            end
          end
          Log.info "Quiet period elapsed for #{project.name}."
        end
        return revisions
      else
        Log.info "Not polling #{project.name} since its central scm repo doesn't seem to exist"
      end
    end
  end
end
