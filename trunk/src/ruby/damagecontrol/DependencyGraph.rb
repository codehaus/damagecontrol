require 'damagecontrol/Project'

class DependencyGraph
	attr_reader :projects
	
	def initialize
		@projects = Array.new
	end
	
	def add_project(name)
		project = Project.new(name)
		@projects << project
		project
	end
end