# some ruby distros include an old crappy REXML-version
begin
  require 'rexml/pullparser'
rescue
end
begin
  require 'rexml/parsers/pullparser'
rescue
end


module DamageControl

  # This class parses a CruiseControl XML log
  # and calls callback methods (typesafe "SAX" events)
  # on a Build object
  class CruiseControlLogParser
    def parse(cc_log_file, build)
      File.open(cc_log_file) do |io|
        parser = REXML::PullParser.new(io)
        parse_top_level(parser, build)
      end

      nil        
    end
    
  private

    def parse_top_level(parser, build)
      while parser.has_next?
        res = parser.next
        handle_error(res)
                
        parse_info(parser, build) if res.start_element? and res[0] == 'info'
        parse_build(res, parser, build) if res.start_element? and res[0] == 'build'
      end
    end

    def parse_info(parser, build)
      while parser.has_next?
        res = parser.next
        handle_error(res)
                
        if res.start_element? and res[0] == 'property'
          build.label              = res[1]['value'] if res[1]['name'] == 'label'
          build.timestamp          = res[1]['value'] if res[1]['name'] == 'cctimestamp'
        end
                
        return if res.end_element? and res[0] == 'info'
      end
    end
 
    def parse_build(res, parser, build)
      if res[1]['error']
        build.error_message = res[1]['error']
        build.successful = false
      else
        build.successful = true
      end
    end

    def handle_error(res)
      raise res[1] if res.error?
    end
        
  end

end