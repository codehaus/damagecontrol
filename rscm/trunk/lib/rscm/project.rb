require 'rscm'
require 'rscm/cvs/cvs'
require 'rscm/svn/svn'
require 'rscm/starteam/starteam'

module RSCM
  class Project

    attr_accessor :name
    attr_accessor :description
    attr_accessor :home_page
    attr_accessor :rss_enabled

    attr_accessor :scm
    attr_accessor :tracker
  
    def initialize
      @scm = nil
      @tracker = Tracker::Null.new
    end
  
    def form_file
      File.dirname(__FILE__) + "/project.rhtml"
    end
  end
end
