require 'yaml'
require 'drb'
require 'rss/maker'
require 'fileutils'
require 'rscm/directories'
require 'rscm/time_ext'
require 'rscm/changes'
require 'rscm/diff_parser'
require 'rscm/diff_htmlizer'
require 'rscm/visitor/yaml_persister'
require 'rscm/visitor/diff_persister'
require 'rscm/visitor/rss_writer'

class String
  # Turns a String into a new int or time, representing the next changeset id
  def next_changeset_id
    if(self =~ /20\d\d\d\d\d\d\d\d\d\d\d\d/)
      # It's a timestamp string - convert to time.
      Time.parse_ymdHMS(self) + 1
    else
      # It's an arbitrary integer.
      self.to_i + 1
    end
  end
end

module RSCM
  # Represents a project with associated SCM, Tracker and SCMWeb
  class Project

    attr_accessor :name
    attr_accessor :description
    attr_accessor :home_page

    attr_accessor :scm
    attr_accessor :tracker
    attr_accessor :scm_web
  
    # Loads the project with the given +name+.
    def Project.load(name)
      File.open(Directories.project_config_file(name)) do |io|
        YAML::load(io)
      end
    end

    # Loads all projects
    def Project.find_all
      Directories.project_names.collect do |name|
        Project.load(name)
      end
    end
  
    def initialize
      @scm = nil
      @tracker = Tracker::Null.new
      @scm_web = SCMWeb::Null.new
    end

    # Saves the state of this project to persistent store (YAML)
    def save
      f = project_config_file
      FileUtils.mkdir_p(File.dirname(f))
      File.open(f, "w") do |io|
        YAML::dump(self, io)
      end
      
      POLLER.add_project(self) if POLLER

    end
    
    # Path to file containing pathnames of latest checked out files.
    def checkout_list_file
      Directories.checkout_list_file(name)
    end
    
    # Checks out files to project's checkout directory.
    # Writes the checked out files to +checkout_list_file+.
    def checkout
      File.open(checkout_list_file, "w") do |f|
        scm.checkout(checkout_dir) do |file_name|
          f << file_name << "\n"
          f.flush
        end
      end
    end

    # Polls SCM for new changesets and updates
    # RSS and YAML files on disk. If this is the first poll (i.e. no changesets have
    # been previously stored on disk), then changesets since +from_if_first_poll+
    # will be retrieved.
    def poll(from_if_first_poll=Time.epoch)
      start = Time.now
      all_start = start

      from = next_changeset_identifier || from_if_first_poll
      
puts "Getting changesets for #{name} from #{from}"
      # TODO: Use a yield model here so we don't have to cache as much in memory.
      changesets = @scm.changesets(checkout_dir, from)

puts "Got changesets for #{@name} in #{Time.now.difference_as_text(start)}"
      start = Time.now

      if(changesets.empty?)
puts "No changesets for #{name} from #{from}"
      else
      
        # Save the changesets to disk as YAML
puts "Saving changesets for #{@name}"
        changesets.accept(changesets_persister)
puts "Saved changesets for #{@name} in #{Time.now.difference_as_text(start)}"
      start = Time.now

        # Get the diff for each change and save them.
        # They may be turned into HTML on the fly later (quick)
puts "Getting diffs for #{@name}"
        dp = RSCM::Visitor::DiffPersister.new(@scm, @name)
        changesets.accept(dp)
puts "Saved diffs for #{@name} in #{Time.now.difference_as_text(start)}"
      start = Time.now

        # Now we need to update the RSS. The RSS spec says max 15 items in a channel,
        # (http://www.chadfowler.com/ruby/rss/)
        # We'll get upto the latest 15 changesets and turn them into RSS.
puts "Generating RSS for #{@name}"
        last_changesets = changesets_persister.load_upto(changesets_persister.latest_id, 15)
        RSS::Maker.make("2.0") do |rss|
          FileUtils.mkdir_p(File.dirname(changesets_rss_file))
          File.open(changesets_rss_file, "w") do |io|
            rss_writer = RSCM::Visitor::RssWriter.new(
              rss,
              "Changesets for #{@name}",
              "http://localhost:4712/", # TODO point to web version of changeset
              @description, 
              @tracker || Tracker::Null.new, 
              @scm_web || SCMWeb::Null.new        
            )
            last_changesets.accept(rss_writer)
            io.write(rss.to_rss)
          end
        end
puts "Generated diffs for #{@name} in #{Time.now.difference_as_text(start)}"
puts "Polled everyting from #{@name} in #{Time.now.difference_as_text(all_start)}"

      end
    end

    # Returns the id (string label or time) that should be used to get the next (unrecorded)
    # changeset. This is the id *following* the latest recorded changeset. 
    # This id is determined by looking at the directory names under 
    # +changesets_dir+. If there are none, this method returns nil.
    def next_changeset_identifier(d=changesets_dir)
      # See String extension at top of this file.
      latest_id = RSCM::Visitor::YamlPersister.new(d).latest_id
      latest_id ? latest_id.to_s.next_changeset_id : nil
    end
    
    # Where RSS is written.
    def changesets_rss_file
      Directories.changesets_rss_file(name)
    end
    
    def checked_out?
      @scm.checked_out?(checkout_dir)
    end
    
    def exists?
      File.exists?(project_config_file)
    end

    def scm_exists?
      scm.exists?
    end

    def checkout_dir
      Directories.checkout_dir(name)
    end
    
    def delete_working_copy
      File.delete(checkout_dir)
    end

    def changesets_rss_exists?
      File.exist?(changesets_rss_file)
    end

    def changesets_dir
      Directories.changesets_dir(name)
    end
    
    def changeset_html_file(changeset_id)
      Directories.changeset_html_file(name, changeset_id)
    end
    
    def changesets(changeset_id, prior)
      changesets_persister.load_upto(changeset_id, prior)
    end

    def changeset_ids
      changesets_persister.ids
    end
    
    def latest_changeset_id
      changesets_persister.latest_id
    end
    
    def delete
      File.delete(Directories.project_dir(name))
    end
    
    def == (o)
      return false unless o.is_a?(Project)
      name == o.name
    end

  private

    def changesets_persister
      RSCM::Visitor::YamlPersister.new(changesets_dir)
    end

    def project_config_file
      Directories.project_config_file(name)
    end

  end
end
