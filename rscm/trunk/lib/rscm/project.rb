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
  
    def Project.load(name)
      File.open(Directories.project_config_file(name)) do |io|
        YAML::load(io)
      end
    end

    def Project.find_all
      Directories.project_names.collect do |name|
        Project.load(name)
      end
    end
  
    def initialize
      @scm = nil
      @tracker = Tracker::Null.new
    end

    def save
      f = Directories.project_config_file(name)
      FileUtils.mkdir_p(File.dirname(f))
      File.open(f, "w") do |io|
        YAML::dump(self, io)
      end      
    end
  end
end
