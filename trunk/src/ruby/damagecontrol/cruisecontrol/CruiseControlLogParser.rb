require 'rexml/pullparser'

module DamageControl

  # This class parses a CruiseControl XML log
  # and calls callback methods (typesafe "SAX" events)
  # on a BuildResult object
  class CruiseControlLogParser
    def parse(cc_log_file, build_result)
      File.open(cc_log_file) do |io|
        parser = REXML::PullParser.new(io)
        parse_top_level(parser, build_result)
      end

      nil        
    end
    
  private

    def parse_top_level(parser, build_result)
      while parser.has_next?
        res = parser.next
        handle_error(res)
                
        parse_info(parser, build_result) if res.start_element? and res[0] == 'info'
        parse_build(res, parser, build_result) if res.start_element? and res[0] == 'build'
      end
    end

    def parse_info(parser, build_result)
      while parser.has_next?
        res = parser.next
        handle_error(res)
                
        if res.start_element? and res[0] == 'property'
          build_result.label              = res[1]['value'] if res[1]['name'] == 'label'
          build_result.timestamp          = res[1]['value'] if res[1]['name'] == 'cctimestamp'

          build_result.project_name       = res[1]['value'] if res[1]['name'] == 'projectname'
          build_result.scm_spec           = res[1]['value'] if res[1]['name'] == 'scm_spec'
          build_result.build_command_line = res[1]['value'] if res[1]['name'] == 'build_command_line'
          build_result.build_path         = res[1]['value'] if res[1]['name'] == 'build_path'
        end
                
        return if res.end_element? and res[0] == 'info'
      end
    end
 
    def parse_build(res, parser, build_result)
      if res[1]['error']
        build_result.error_message = res[1]['error']
        build_result.successful = false
      else
        build_result.successful = true
      end
    end

    def handle_error(res)
      raise res[1] if res.error?
    end
        
  end

end