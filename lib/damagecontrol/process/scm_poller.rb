require File.dirname(__FILE__) + '/base'

module DamageControl
  module Process
    
    # Polls projects' SCMs for new revisions and persists them in the database.
    class ScmPoller < Base

      def run
        forever do |project|
          poll_if_needed(project)
        end
      end
      
      # Polls for new revisions and requests a build for the last one (if there were any).
      # Polling won't happen if the +project+'s scm is nil or if the +project's+ polling
      # strategy says 'don't poll'
      def poll_if_needed(project)
        should_poll = false
        case(project.scm.revision_detection)
          when "ALWAYS_POLL" 
            should_poll = true
          when "POLL_IF_REQUESTED" 
            should_poll = project.pop_poll_request
        end
        if(should_poll)
          project.prepare_scm # Create .cvspass file or do other preparation
          rscm_revisions = project.scm.poll_new_revisions(
            :latest_revision => project.latest_revision
          )
          new_revisions = persist_revisions(project, rscm_revisions)
          project.new_revisions_detected(new_revisions)
        end
      end

      # Stores revisions in the database and returns the persisted revisions.
      def persist_revisions(project, rscm_revisions)
        position = project.revisions.length
      
        # There may be a lot of inserts. Doing it in one txn will speed it up
        Revision.transaction do
          rscm_revisions.collect do |rscm_revision|
            position += 1
            rscm_revision.message = project.tracker.markup(rscm_revision.message) if project.tracker
            Revision.create_from_rscm_revision(project, rscm_revision, position)
          end
        end
      end
    end
  end
end
