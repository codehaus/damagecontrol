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
    attr_accessor :rss_enabled

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
      
      if(rss_enabled)
        RSS_SERVICE.add_project(self)
      end

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
    
    # Writes RSS for the last week to file. See +rss_file+
    def write_rss
      # approx 1 week back
      from = Time.new - 3600*24*7
      changesets = @scm.changesets(checkout_dir, from)

      FileUtils.mkdir_p(File.dirname(rss_file))
      File.open(rss_file, "w") do |io|
        rss = changesets.to_rss(
          "Changesets for #{name}", 
          @home_page, # TODO point to web version of changeset
          @description, 
          @tracker || Tracker::Null.new, 
          @scm_web || SCMWeb::Null.new
        )
        io.write(rss)
      end
    end

    # Where RSS is written.
    def rss_file
      Directories.rss_file(name)
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

  private

    def project_config_file
      Directories.project_config_file(name)
    end
  end
end
