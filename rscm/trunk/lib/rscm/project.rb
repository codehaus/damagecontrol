require 'yaml'
require 'drb'
require 'fileutils'
require 'rscm/directories'

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
      
      RSS_SERVICE.add_project(self) if RSS_SERVICE

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
      from = next_changeset_time || from_if_first_poll

      changesets = @scm.changesets(checkout_dir, from)
      if(!changesets.empty?)
        changesets.save(changesets_dir)

        # Now we need to update the RSS. The RSS spec says max 15 items in a channel,
        # So we'll get upto the latest 15 changesets and RSS it..
        # (http://www.chadfowler.com/ruby/rss/)
        last_changesets = ChangeSets.load_upto(changesets_dir, 15)
        title = "Changesets for #{@name}"
        last_changesets.write_rss(
          title,
          changesets_rss_file,
          "http://localhost:4712/", # TODO point to web version of changeset
          @description || title, 
          @tracker || Tracker::Null.new, 
          @scm_web || SCMWeb::Null.new        
        )
      end
    end

    # Returns the time that should be used to get the next (unrecorded)
    # changeset. This is the time of the latest recorded changeset +1. 
    # This time is determined by looking at the directory names under 
    # +changesets_dir+. If there are none, this method returns nil.
    def next_changeset_time(d=changesets_dir)
      changestet_dirs = Dir["#{d}/*"]
      latest_dir = changestet_dirs.sort.reverse.find {|f| File.directory?(f)}
      return nil unless latest_dir
      latest = File.basename(latest_dir)
      Time.parse_ymdHMS(latest) + 1
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

  private

    def project_config_file
      Directories.project_config_file(name)
    end

  end
end
