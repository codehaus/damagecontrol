require 'damagecontrol/DependencyGraph'

class AllTraverser
	def traverse(dependency_graph)
		@projects_to_build = dependency_graph.projects
		@projects_built = Array.new
		while (!all_projects_built())
			project = next_buildable_project()
			yield project
		end
	end
	
	def all_projects_built
		@projects_to_build.empty?
	end
	
	def next_buildable_project
		project = @projects_to_build.find {|project| 
			dependencies_left_to_build_for_project(project).empty?
		}
		@projects_to_build.delete(project)
		@projects_built << project
		project
	end
	
	def dependencies_left_to_build_for_project(project) 
		project.dependencies - @projects_built
	end
end