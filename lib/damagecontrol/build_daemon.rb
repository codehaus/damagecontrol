module DamageControl
  
  class BuildDaemon
    CYCLE_PAUSE = 20

    cattr_accessor :logger
    
    def initialize(scm_poller)
      @scm_poller = scm_poller
    end
    
    def run
      puts "==> DamageControl daemon started"
      while(true)
        handle_all_projects_once
        sleep CYCLE_PAUSE
      end
    end

    def handle_all_projects_once
      Project.find(:all).each do |project|
        # assumptions:
        # 1) builds cannot be created for revisions that already have a pending (not started) build.
        #    anyone who tries to create one should either get an exception or just
        #    get the existing build. as much as possible of these constraints should be enforced in
        #    Build.before_save and Revision.builds.
        #
        # 2) polling for a project's scm revisions or executing its builds should not occur if the 
        #    project is marked as 'busy' (typically by another daemon process)
        #
        # 3) a project should always be marked as busy right before it's being polled
        # 3) polling and detecting revision should go straight to build
        # 4) polling or building project should mark it as busy in the db.
        #
        
        # We're reloading the project here, since its locked state may have changed
        project.reload
        unless(project.lock_time)
          project.lock_time = Time.now.utc
          project.save
          handle_project(project) 
          project.lock_time = false
          project.save
        end
      end
    end
    
    def handle_project(project)
      pending_build = project.next_pending_build
      if(pending_build)
        pending_build.execute!
      elsif(project.uses_polling)
        latest_revision = @scm_poller.poll_and_persist_new_revisions(project)
        if(latest_revision)
          build = latest_revision.request_build(Build::SCM_POLLED)
          build.execute!
        end
      end
    end
  end

end