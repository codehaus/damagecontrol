require 'yaml'
require 'rscm'

module RSCM
  class RssService
  
    def initialize(config)
      dc = {
        :scm => SVN.new("svn://beaver.codehaus.org/damagecontrol/svn/rscm/trunk", "rscm/trunk"),
        :tracker => Tracker::JIRA.new("http://jira.codehaus.org/"),
        :scm_web => SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
      }

      dc[:scm].checkout("dc")
      changesets = dc[:scm].changesets("dc", nil)
      puts changesets.to_rss(
        "DamageControl Changesets", 
        "http://damagecontrol.codehaus.org/", 
        "This feed contains SCM changes for the DamageControl project", 
        dc[:tracker], 
        dc[:scm_web])

    end

  end
end

RSCM::RssService.new(ARGV[0])