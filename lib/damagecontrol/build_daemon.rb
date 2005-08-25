module DamageControl
  
  class BuildDaemon
    cattr_accessor :logger
    
    def run
      puts "==> DamageControl daemon started"
      while(true)
        run_once
        sleep 1
      end
    end

    def run_once
      Project.find(:all).each do |project|
        poll(project)
        build(project)
      end
    end
    
    def build(project)
      latest_revision = project.latest_revision
      if (latest_revision && latest_revision.builds.empty?)
        build = latest_revision.builds.create(:reason => Build::SCM_POLLED)
        build.execute!
      end
    end

    def poll(project)
      poller = ScmPoller.new
      begin
        poller.persist_revisions(project, poller.poll_new_revisions(project))
      rescue => e
        STDERR.puts "Error polling #{project.name}"
        STDERR.puts  e.message
        STDERR.puts "  " + e.backtrace.join("  \n")        
      end
    end
  end

end