require 'rscm/changes'
require 'rscm/directories'
require 'rscm/project'
require 'rscm/tracker'
require 'rscm/abstract_scm'
# scms
require 'rscm/scm_web'
require 'rscm/cvs/cvs'
require 'rscm/svn/svn'
require 'rscm/starteam/starteam'
require 'rscm/darcs/darcs'
require 'rscm/mooky/mooky'

module RSCM

  SCMS = [
# Uncomment this to see Mooky in action in the web interface!
#    Mooky.new,
    CVS.new, 
    SVN.new, 
    StarTeam.new
  ]

  TRACKERS = [
    Tracker::Null.new, 
    Tracker::Bugzilla.new, 
    Tracker::JIRA.new,
    Tracker::RubyForge.new,
    Tracker::SourceForge.new,
    Tracker::Scarab.new
  ]

  SCM_WEBS = [
#    SCMWeb::Null.new, 
#    SCMWeb::ViewCVS.new, 
#    SCMWeb::Fisheye.new
  ]
  
end

if(__FILE__ == $0)
  # Run as server
  require 'drb'

  class RSCMServer
    def find_all_projects
      RSCM::Project.find_all
    end

    def load_project(name)
      RSCM::Project.load(name)
    end
  end

  DRb.start_service('druby://localhost:9000', RSCMServer.new)  
  DRb.thread.join # Don't exit just yet!
end