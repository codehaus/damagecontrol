
require 'damagecontrol/Timer'
require 'damagecontrol/FileUtils'

module DamageControl

	class FilePoller
		attr_reader :dir_to_poll
			
		include TimerMixin
		include FileUtils

		def initialize(dir_to_poll)
			@dir_to_poll = dir_to_poll
			determine_existing_files
		end
		
		def tick(time)
			Dir.foreach(dir_to_poll) do |filename|
				new_file("#{dir_to_poll}/#{filename}") if is_new_file(filename)
			end
			determine_existing_files
			schedule_next_tick
		end
		
		def is_new_file(filename)
			!@existing_files.index(filename)
		end
		
		def determine_existing_files
			@existing_files = []
			Dir.foreach(dir_to_poll) do |filename|
				@existing_files << filename
			end
		end
		
		def new_file(file)
			puts "detected new file #{file}"
		end
		
	end
		
end