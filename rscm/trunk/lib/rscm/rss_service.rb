require 'yaml'
require 'rscm'
require 'webrick'

module RSCM
  class RssService

    def initialize(scm, checkout_dir, rss_file, title, url, description, tracker, scm_web, port, interval)
      @scm, @checkout_dir, @rss_file, @title, @url, @description, @tracker, @scm_web, @port, @interval = scm, checkout_dir, rss_file, title, url, description, tracker, scm_web, port, interval
    end
    
    def start
      @httpd = WEBrick::HTTPServer.new(
        {
          :Port => @port,
          :DocumentRoot => File.dirname(@rss_file),
          :ServerType => Thread
        }
      ).start

      # Not required for all SCMs, but for some.
      @scm.checkout(@checkout_dir)

      while(true)
        # approx 1 week back
        from = Time.new - 3600*24*7
        changesets = @scm.changesets(@checkout_dir, from)
        File.open(@rss_file, "w") do |io|
          io.puts changesets.to_rss(
            @title, 
            @url, 
            @description, 
            @tracker, 
            @scm_web
          )
        end
        sleep(@interval)
      end
    end
  end
  
end

if $0 == __FILE__
  generator = nil
  if(ARGV[0])
    service = YAML::load_file(ARGV[0])
  else
    scm = RSCM::SVN.new("svn://beaver.codehaus.org/damagecontrol/svn/rscm/trunk", "rscm/trunk")
    checkout_dir = "target/rscm-rss"
    rss_file = "target/rscm.xml"
    title = "RSCM Changesets"
    url = "http://damagecontrol.codehaus.org/"
    description = "This feed contains SCM changes for the RSCM project (eating its own dogfood)"
    tracker = RSCM::Tracker::JIRA.new("http://jira.codehaus.org/", "DC")
    scm_web = RSCM::SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")

    service = RSCM::RssService.new(scm, checkout_dir, rss_file, title, url, description, tracker, scm_web, 8090, 10)
  end

#  puts YAML::dump(generator)
  
  service.start
end
