class Project
	attr_reader :name
	attr_reader :dependencies
	
	def initialize(name)
		@name = name
		@dependencies = Array.new
	end
	
	def add_tip_dependency(project)
		@dependencies.push(project)
	end
end