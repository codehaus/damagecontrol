require 'rscm/logging'
require 'rscm/time_ext'

module DamageControl
  # Polls all projects in intervals.
  class Poller
    attr_reader :projects

    def initialize(sleeptime=60)
      @projects = []
      @sleeptime = sleeptime
    end

    # Adds a project to poll. If the project is already added it is replaced
    # with then new one, otherwise appended to the end.
    def add_project(project)
      index = @projects.index(project) || @projects.length
      @projects[index] = project
    end
    
    # Polls all registered projects and persists RSS, changesets and diffs to disk.
    def poll
      @projects.each do |project|
        begin
          if(project.scm_exists?)
            project.poll do |changesets|
              start = Time.now
        
              if(changesets.empty?)
                Log.info "No changesets for #{project.name}"
              else
              
                # Save the changesets to disk as YAML
                Log.info "Saving changesets for #{project.name}"
                changesets.accept(project.changesets_persister)
                Log.info "Saved changesets for #{project.name} in #{Time.now.difference_as_text(start)}"
                start = Time.now
        
                # Get the diff for each change and save them.
                # They may be turned into HTML on the fly later (quick)
                Log.info "Getting diffs for #{project.name}"
                dp = RSCM::Visitor::DiffPersister.new(project.scm, project.name)
                changesets.accept(dp)
                Log.info "Saved diffs for #{project.name} in #{Time.now.difference_as_text(start)}"
                start = Time.now
        
                # Now we need to update the RSS. The RSS spec says max 15 items in a channel,
                # (http://www.chadfowler.com/ruby/rss/)
                # We'll get upto the latest 15 changesets and turn them into RSS.
                Log.info "Generating RSS for #{project.name}"
                last_15_changesets = project.changesets_persister.load_upto(changesets_persister.latest_id, 15)
                RSS::Maker.make("2.0") do |rss|
                  FileUtils.mkdir_p(File.dirname(project.changesets_rss_file))
                  File.open(changesets_rss_file, "w") do |io|
                    rss_writer = RSCM::Visitor::RssWriter.new(
                      rss,
                      "Changesets for #{@name}",
                      "http://localhost:4712/", # TODO point to web version of changeset
                      project.description, 
                      project.tracker || Tracker::Null.new, 
                      project.scm_web || SCMWeb::Null.new        
                    )
                    last_15_changesets.accept(rss_writer)
                    io.write(rss.to_rss)
                  end
                end
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
