require 'damagecontrol/Build'

# some ruby distros include an old crappy REXML-version
begin
  require 'rexml/parsers/pullparser'
rescue LoadError
  raise "some ruby distros include an older version of REXML, please remove RUBY_HOME/lib/site_ruby/1.8/rexml"
end


module DamageControl

  # This class parses a CruiseControl XML log
  # and calls callback methods (typesafe "SAX" events)
  # on a Build object
  class CruiseControlLogParser
    
    attr_reader :website_baseurl

    def initialize(website_baseurl)
      @website_baseurl = website_baseurl
    end

    def parse(cc_log_file, build)
      File.open(cc_log_file) do |io|
        parser = REXML::Parsers::PullParser.new(io)
        parse_top_level(parser, build)
      end

      nil        
    end
    
  private

    def parse_top_level(parser, build)
      # these files can get might big, so we need to break fast as soon as we got the info we need
      parsed_info = false
      parsed_build = false
      while parser.has_next? && !parsed_info || !parsed_build
        res = parser.pull
        handle_error(res)
                
        if res.start_element? and res[0] == 'info'
	  parse_info(parser, build)
	  parsed_info = true
	end
        if res.start_element? and res[0] == 'build'
	  parse_build(res, parser, build)
	  parsed_build = true
	end
      end
    end

    def parse_info(parser, build)
      while parser.has_next?
        res = parser.pull
        handle_error(res)
                
        if res.start_element? and res[0] == 'property'
          build.label = res[1]['value'] if res[1]['name'] == 'label'
          build.timestamp = res[1]['value'] if res[1]['name'] == 'cctimestamp'
          build.project_name = res[1]['value'] if res[1]['name'] == 'projectname'
	  build.url = logfile_to_url(res[1]['value']) if res[1]['name'] == 'logfile'
        end
                
        return if res.end_element? and res[0] == 'info'
      end
    end

    def logfile_to_url(logfile)
      if logfile=~/^(\/|\\)(.*)\.xml$/
	"#{website_baseurl}?log=#{$2}"
      else
        "<unknown url>"
      end
    end
 
    def parse_build(res, parser, build)
      if res[1]['error']
        build.error_message = res[1]['error']
        build.status = Build::FAILED
      else
        build.status = Build::SUCCESSFUL
      end
    end

    def handle_error(res)
      raise res[1] if res.error?
    end
        
  end

end
