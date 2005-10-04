module DamageControl
  
  class BuildDaemon
    CYCLE_PAUSE = 20

    cattr_accessor :logger
    
    def initialize(scm_poller)
      @scm_poller = scm_poller
    end
    
    def run
      at_exit do
        logger.info "=> DamageControl builder exiting"
      end
      begin
        logger.info "=> DamageControl builder started"
        loop do
          handle_all_projects_once
          sleep CYCLE_PAUSE
        end
      rescue SignalException => e
        logger.info "=> DamageControl builder received signal to shut down"
        exit!(1)
      end
    end

    def handle_all_projects_once
      projects = Project.find(:all)
      if(projects.size == 0)
        logger.info "No projects in the database" if logger
        return
      end
      
      projects.each do |project|
        # assumptions:
        # 1) builds cannot be created for revisions that already have a pending (not started) build.
        #    anyone who tries to create one should either get an exception or just
        #    get the existing build. as much as possible of these constraints should be enforced in
        #    Build.before_save and Revision.builds. TODO!
        #
        # 2) polling for a project's scm revisions or executing its builds should not occur if the 
        #    project is marked as 'busy' (typically by another daemon process)
        #
        # 3) polling and detecting revision should go straight to build
        # 4) polling or building project should mark it as busy in the db.
        #
        
        # We're reloading the project here, since its locked state may have changed
        begin
          project.reload
        
          # TODO: We should set the lock_time flag and save the project to avoid other parallel
          # daemon processes from handling the project. -But how do we ensure that locked projects
          # don't remain locked if the locking daemon goes down before a project is unlocked?
          # Maybe we need some inter-process communication - Drb or something. That opens up a new
          # question: How do the processes get to know each other? Is there a simpler way around 
          # this problem?
          handle_project(project) 
        rescue ActiveRecord::RecordNotFound => e
          logger.error "Couldn't handle project #{project.name}. It looks like it was recently deleted" if logger
        rescue SignalException => e
          raise e
        rescue Exception => e
          if(logger)
            logger.error "Couldn't handle project #{project.name}. Unexpected error: #{e.message}"
            logger.error e.backtrace.join("\n")
          end
        end
      end
    end
    
    def handle_project(project)
      logger.info "Checking project #{project.name}" if logger
      pending_build = project.latest_pending_build
      if(pending_build)
        logger.info "Pending build found for project #{project.name}" if logger
        pending_build.execute!
      elsif(project.scm.uses_polling?)
        logger.info "No pending builds found for project #{project.name}, polling #{project.scm.visual_name} for new revisions" if logger
        latest_new_revision = @scm_poller.poll_and_persist_new_revisions(project)
        if(latest_new_revision)
          logger.info "Requesting/executing build for new revision in project #{project.name}" if logger
          project.request_build(Build::SCM_POLLED).execute!
        end
      else
        logger.info "No pending builds for project #{project.name} and not polling its SCM since the project has polling disabled" if logger
      end
    end
  end

end