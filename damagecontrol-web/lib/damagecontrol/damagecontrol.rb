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
    Tracker::Scarab.new,
    Tracker::Trac.new
  ]

  SCM_WEBS = [
#    SCMWeb::Null.new, 
#    SCMWeb::ViewCVS.new, 
#    SCMWeb::Fisheye.new
  ]
