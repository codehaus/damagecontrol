require 'damagecontrol/BuildEvents'
require 'ftools'

module DamageControl

	class HTMLPublisher
		
		def process_message(event)
			if event.is_a? BuildCompleteEvent
				path = "dc/#{event.build.project_name}/website"
				filename = "buildresult.html"
				File.makedirs(path)
				create_file(path + "/" +filename)
				
			end
		end
		
		def create_file(file_name)
			file = File.new(file_name, "w")
			file.close
		end
	end
end