require 'rscm/logging'
require 'rscm/time_ext'
require 'damagecontrol/project'

module DamageControl
  # Polls all projects in intervals.
  class Poller
    attr_reader :projects

    # Creates a new poller. Takes a block that will
    # receive |project, changesets| each time new
    # +changesets+ are found in a polled +project+
    def initialize(sleeptime=60, &proc)
      @projects = []
      @sleeptime = sleeptime
      @proc = proc
    end

    # Adds a project to poll. If the project is already added it is replaced
    # with then new one, otherwise appended to the end.
    def add_project(project)
      index = @projects.index(project) || @projects.length
      @projects[index] = project
    end
    
    # Polls all registered projects and persists RSS, changesets and diffs to disk.
    # If a block is passed, the project and the changesets will be yielded to the block
    # for each new changesets object.
    def poll
      @projects.each do |project|
        begin
          if(project.scm_exists?)
            project.poll do |changesets|
              if(changesets.empty?)
                Log.info "No changesets for #{project.name}"
              else
                @proc.call(project, changesets)
              end
            end
          end
        rescue => e
          $stderr.puts "Error polling #{project.name}"
          $stderr.puts e.message
          $stderr.puts "  " + e.backtrace.join("  \n")
        end
      end
    end
    
    # Runs +poll+ in a separate thread.
    def start
      add_all_projects
      @t = Thread.new do
        while(true)
          poll
          sleep(@sleeptime)
        end
      end
    end
    
    # Stops thread after a +start+.
    def stop
      @t.kill if @t && @t.alive?
    end

    # Adds all projects
    def add_all_projects
      Project.find_all.each do |project|
        add_project(project)
      end
    end    
  end
end
