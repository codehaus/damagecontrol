require 'damagecontrol/Hub'
require 'damagecontrol/FilePoller'
require 'damagecontrol/BuildCompleteEvent'
require 'damagecontrol/Project'

module DamageControl
	class CruiseControlLogPoller < FilePoller
		def initialize(dir, hub)
			super(dir)
			@hub = hub
		end
		
		def new_file(file)
			@hub.publish_message(BuildCompleteEvent.new(Project.new("TODO")))
		end
	end
end