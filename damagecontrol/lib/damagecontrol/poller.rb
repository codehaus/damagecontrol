require 'rscm/logging'
require 'rscm/time_ext'
require 'damagecontrol/project'
require 'damagecontrol/publisher/base'

module DamageControl
  # Polls all projects in intervals.
  class Poller
    attr_reader :projects

    # Creates a new poller. Takes a block that will
    # receive |project, revisions| each time new
    # +revisions+ are found in a polled +project+
    def initialize(projects_dir, sleeptime=60, &proc)
      @projects_dir = projects_dir
      @sleeptime = sleeptime
      @proc = proc
    end

    # Polls all registered projects and persists RSS, revisions and diffs to disk.
    # If a block is passed, the project and the revisions will be yielded to the block
    # for each new revisions object.
    def poll
      Log.info "Starting polling cycle"
      Project.find_all(@projects_dir).each do |project|
        begin
          if(project.scm_exists?)
            project.poll do |revisions|
              if(revisions.empty?)
                Log.info "No revisions for #{project.name}"
              else
                @proc.call(project, revisions)
              end
            end
          else
            Log.info "Not polling #{project.name} since its scm doesn't exist"
          end
        rescue => e
          Log.error "Error polling #{project.name}"
          Log.error  e.message
          Log.error "  " + e.backtrace.join("  \n")
        end
      end
    end
    
    # Runs +poll+ in a separate thread.
    def start
      @t = Thread.new do
        while(true)
          poll
          sleep(@sleeptime)
        end
      end
      @t
    end
    
    # Stops thread after a +start+.
    def stop
      @t.kill if @t && @t.alive?
    end
  end
end
