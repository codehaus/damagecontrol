require 'yaml'
require 'fileutils'
require 'rscm/directories'

module RSCM
  class Project

    attr_accessor :name
    attr_accessor :description
    attr_accessor :home_page
    attr_accessor :rss_enabled

    attr_accessor :scm
    attr_accessor :tracker
  
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
    end

    # Saves the state of this project to persistent store (YAML)
    def save
      f = Directories.project_config_file(name)
      FileUtils.mkdir_p(File.dirname(f))
      File.open(f, "w") do |io|
        YAML::dump(self, io)
      end      
    end
    
    def checkout_list_file
      Directories.checkout_list_file(name)
    end
    
    # Checks out files to project's checkout directory.
    # Writes the checked out files to +checkout_list_file+.
    def checkout
$stderr.puts "CHECKING OUT... #{Thread.current} #{Dir.pwd}"
      File.open(checkout_list_file, "w") do |f|
        scm.checkout(Directories.checkout_dir(name)) do |file_name|
$stderr.puts file_name
          f << file_name << "\n"
        end
      end
$stderr.puts "CHECKED OUT..."
    end
  end
end
