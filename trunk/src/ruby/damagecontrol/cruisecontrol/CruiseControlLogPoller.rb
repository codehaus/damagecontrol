require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'rexml/document'

module DamageControl

	class CruiseControlLogPoller < FilePoller
		def initialize(hub, dir)
			super(dir)
			@hub = hub
		end
		
		def new_file(file)
			evt = parse_cc_log(file)
			@hub.publish_message(evt)
		end

		def parse_cc_log(file)
			projectname = "unknown"
			label = "unknown"
			successful = nil
			error_message = nil
		    
			begin
				log = nil
				File.open(file) do |io|
					log = REXML::Document.new(io)
				end
				info = log.elements['cruisecontrol/info']
				projectname = info.elements["property[@name='projectname']/@value"].to_s
				label = info.elements["property[@name='label']/@value"].to_s
				build_xml = log.elements['cruisecontrol/build']
				if build_xml.attributes['error']
					error_message = build_xml.attributes['error']
					successful = false
				else
					successful = true
				end
			rescue
				puts "could not parse xml-log-file #{file}: #{$!}"
			end
		    
			build = Build.new(projectname)
			evt = BuildCompleteEvent.new(build)
			build.label = label
			build.successful = successful
			build.error_message = error_message
			
			evt
		end
	end
end