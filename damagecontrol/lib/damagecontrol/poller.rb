require 'rscm/logging'
require 'rscm/time_ext'
require 'damagecontrol/project'
require 'damagecontrol/publisher/base'

module DamageControl
  # Polls all projects in intervals.
  class Poller
    attr_reader :projects

    # Creates a new poller. Takes a block that will
    # receive |project, changesets| each time new
    # +changesets+ are found in a polled +project+
    def initialize(sleeptime=60, &proc)
      @sleeptime = sleeptime
      @proc = proc
    end

    # Polls all registered projects and persists RSS, changesets and diffs to disk.
    # If a block is passed, the project and the changesets will be yielded to the block
    # for each new changesets object.
    def poll
      Log.info "Starting polling cycle"
      Project.find_all.each do |project|
        Log.info "Polling #{project.name}"
        begin
          if(project.scm_exists?)
            Log.info "Polling #{project.name}"
            project.poll do |changesets|
              if(changesets.empty?)
                Log.info "No changesets for #{project.name}"
              else
                @proc.call(project, changesets)
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
