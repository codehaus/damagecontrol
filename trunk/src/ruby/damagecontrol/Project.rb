class Project
	attr_reader :name
	attr_accessor :website_directory, :logs_directory, :build_command_line

	def initialize (name)
		@name = name
		@website_directory = "website"
		@website_directory = "logs"
	end
end
