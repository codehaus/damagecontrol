require 'damagecontrol/dependency/Project'

module DamageControl
	module Dependency
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
			
			def get_project(name)
				@projects.find {|project| project.name == name }
			end
		end
	end
end