require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildCompleteEvent'
require 'damagecontrol/Project'

module DamageControl
	class Build
		attr_accessor :label
	end
	
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
			begin
				log = nil
				File.open(file) do |io|
					log = REXML::Document.new(io)
				end
				info = log.elements['cruisecontrol/info']
				projectname = info.elements["property[@name='projectname']/@value"].to_s
				project = Project.new(projectname)
				label = info.elements["property[@name='label']/@value"].to_s
			rescue
			end
			
			evt = BuildCompleteEvent.new(project)
			evt.build = Build.new
			evt.build.label = label

			evt
		end
	end
end