require 'ftools'
require 'damagecontrol/FileUtils'

module DamageControl

	class Build
		include FileUtils

		attr_accessor :project_name
		attr_accessor :website_directory
		attr_accessor :logs_directory
		attr_accessor :basedir
		attr_accessor :build_command_line
		attr_accessor :label
		attr_accessor :successful
		attr_accessor :error_message
		attr_accessor :scm_path
		attr_accessor :timestamp
	
		def initialize (basedir, project_name, build_command_line)
			@basedir = basedir
			@project_name = project_name
			@build_command_line = build_command_line
			
			@website_directory = "website"
			@logs_directory = "logs"
			@timestamp = Build.format_timestamp(Time.now)
		end
		
		def Build.format_timestamp(timestamp)
			timestamp.strftime("%Y%m%d%H%M%S") 
		end
	
		def open_website_file (filename, params="w")
			Dir.mkdir( website_directory ) unless File.exists?( website_directory )
			File.open( website_file(filename), params) { |file|
				yield file
			}
		end
		
		def successful?
			successful
		end

		def open_log_file (filename, params="w")
			Dir.mkdir( website_directory ) unless File.exists?( website_directory )
			File.open( website_file(filename), "w") { |file|
				yield file
			}
		end
	
		def log_file (filename)
			Dir.mkdir( logs_directory ) unless File.exists?( logs_directory )
			logs_directory + File::SEPARATOR + filename
		end
		
		def website_file (filename)
			website_directory + File::SEPARATOR + filename
		end
	
		def log_file? (filename)
			/^.*\.log/ =~ filename
		end
		
		def foreach_log
			Dir.foreach (@logs_directory) { |filename|
				if log_file? (filename)
					name = filename[0, filename.rindex('.')]
					yield(Log.new(name, log_file(filename)))
				end
			}
		end
		
		def build
			cd_base_dir
			IO.popen(build_command_line) do |output|
				output.each_line do |progress|
					yield progress
				end
			end
		end
		
		def cd_base_dir
			File.makedirs(basedir)
			Dir.chdir(basedir) unless basedir.nil?
		end
		
		def ==(other)
			project_name == other.project_name \
				&& timestamp == other.timestamp \
		end
	
	end
	
	class Log
		attr_reader :name, :filename
		
		def initialize (name, filename)
			@name = name
			@filename = filename
		end
		
		def open_log_file (params="r")
			File::open(filename, params) { |file|
				yield(file)
			}
		end
		
	end
	
end