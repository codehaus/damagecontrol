require 'yaml'
require 'rscm'

module RSCM
  class RssService
  
    def initialize(config)
      rscm = {
        :scm => SVN.new("svn://beaver.codehaus.org/damagecontrol/svn/rscm/trunk", "rscm/trunk"),
        :tracker => Tracker::JIRA.new("http://jira.codehaus.org/", "DC"),
        :scm_web => SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
      }

      rscm[:scm].checkout("target/rscm-rss")

      while(true)
        changesets = rscm[:scm].changesets("target/rscm-rss", nil)
puts "writing..."
        File.open("target/rss.xml", "w") do |io|
          io.puts changesets.to_rss(
            "RSCM Changesets", 
            "http://damagecontrol.codehaus.org/", 
            "This feed contains SCM changes for the RSCM project (eating its own dogfood)", 
            rscm[:tracker], 
            rscm[:scm_web])
        end
        sleep(10)
      end
    end

  end
end

#if(ARGV[0] == __FILE__)
  RSCM::RssService.new(ARGV[0])
#end
