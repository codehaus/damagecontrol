module RSCM
  # Polls all projects in intervals.
  class Poller
    attr_reader :projects

    def initialize
      @projects = []
    end

    # Adds a project to poll
    def add_project(project)
      @projects << project unless @projects.index(project)
    end
    
    # Polls all registered projects
    def poll
      @projects.each do |project|
        begin
          project.poll
        rescue => e
          $stderr.puts "Error polling #{project.name}"
          $stderr.puts e.message
          $stderr.puts "  " + e.backtrace.join("  \n")
        end
      end
    end
    
    # Runs +poll+ in a separate thread.
    def start(sleeptime=60)
      @t = Thread.new do
        while(true)
          poll
          sleep(sleeptime)
        end
      end
    end
    
    # Stops thread after a +start+.
    def stop
      @t.kill if @t && @t.alive?
    end

    # Adds all projects with rss enabled
    def add_all_projects
      Project.find_all.each do |project|
        add_project(project)
      end
    end
  end
end