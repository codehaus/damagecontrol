require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'rexml/pullparser'

module DamageControl

    class CruiseControlLogPoller < FilePoller
        attr_accessor :current_build
    
	def initialize(hub, dir)
		super(dir)
		@hub = hub
	end
	
	def new_file(file)
		evt = parse_cc_log(file)
		@hub.publish_message(evt)
	end

	def parse_cc_log(file)		    
		self.current_build = Build.new(nil, "unknown", "unknown")
		current_build.label = "unknown"
		current_build.successful = nil
		current_build.error_message = nil            
		
		begin
			log = nil
			File.open(file) do |io|
				parser = REXML::PullParser.new(io)
				parse_top_level(parser)
			end
		rescue
			puts "could not parse xml-log-file #{file}: #{$!}"
		end
	    
		evt = BuildCompleteEvent.new(current_build)
		
		evt
	end
        
        def handle_error(res)
                raise res[1] if res.error?
        end
        
        def parse_top_level(parser)
            while parser.has_next?
                res = parser.next
                handle_error(res)
                
                parse_build(res, parser) if res.start_element? and res[0] == 'build'
                parse_info(res, parser) if res.start_element? and res[0] == 'info'
            end
        end
         
        def parse_info(res, parser)
            while parser.has_next?
                res = parser.next
                handle_error(res)
                
                if res.start_element? and res[0] == 'property'
                    current_build.project_name = res[1]['value'] if res[1]['name'] == 'projectname'
                    current_build.label = res[1]['value'] if res[1]['name'] == 'label'
                    current_build.timestamp = res[1]['value'] if res[1]['name'] == 'cctimestamp'
                end
                
                return if res.end_element? and res[0] == 'info'
            end
        end
         
        def parse_build(res, parser)
            if res[1]['error']
                current_build.error_message = res[1]['error']
                current_build.successful = false
            else
                current_build.successful = true
            end
        end
    end

end