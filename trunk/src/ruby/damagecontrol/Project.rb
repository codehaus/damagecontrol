class Project
	attr_reader :name
	attr_accessor :website_directory, :logs_directory, :build_command_line

	def initialize (name)
		@name = name
		@website_directory = "website"
		@logs_directory = "logs"
	end

	def open_website_file (filename, params="w")
		Dir.mkdir( website_directory ) unless File.exists?( website_directory )
		File.open( website_file(filename), params) { |file|
			yield file
		}
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

	def is_log_file (filename)
		/^.*\.log/ =~ filename
	end
	
	def foreach_log
		Dir.foreach (@logs_directory) { |filename|
			if is_log_file (filename)
				name = filename[0, filename.rindex('.')]
				yield(Log.new(name, log_file(filename)))
			end
		}
	end
	
	def build
		IO.popen(build_command_line) {|f|
			yield(f)
		}
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