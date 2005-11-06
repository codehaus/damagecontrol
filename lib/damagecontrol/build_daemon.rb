module DamageControl
  
  # This is the main class of the daemon process.
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
        begin
          project.reload
        
          # TODO: We must lock the project (persistent lock) to prevent other processes from handling the
          # same project.
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
      
      # We'll put all pending and new builds in here...
      builds = []
      builds.concat(project.pending_builds)
      if(project.scm && project.scm.uses_polling?)

        latest_new_revision = @scm_poller.poll_and_persist_new_revisions(project)
        if(latest_new_revision)
          builds.concat(latest_new_revision.request_builds(Build::SCM_POLLED))
        end
      end
      
      local_builds, slave_managed_builds = builds.partition {|build| build.build_executor.is_master}
      
      # The slave-managed builds are fast to build, since all that happens is to zip up the working copies.
      slave_managed_builds.each do |build|
        build.execute!
      end
      
      # We'll only build one of the pending local builds to avoid spending too much time in one project.
      local_builds[0].execute! if local_builds[0]
    end
    
  end
end