require 'rscm/changes'
require 'rscm/abstract_scm'
require 'rscm/project'
require 'rscm/tracker'
require 'rscm/scm_web'
require 'rscm/cvs/cvs'
require 'rscm/svn/svn'
require 'rscm/starteam/starteam'
require 'rscm/darcs/darcs'
require 'rscm/directories'

module RSCM

  SCMS = [
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