require 'test/unit'

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

class AllTraverserTest < Test::Unit::TestCase
 	def setup
 		@graph = DependencyGraph.new
	end

	def project(name)
		@graph.add_project(name)
	end
	
	def create_traverser
		return AllTraverser.new
	end
	
	def assert_build_order(expected_build_order)
		actual_build_order = ""
		traverser = create_traverser()
		traverser.traverse(@graph)  {|project| actual_build_order += project.name}
		assert_equal(expected_build_order, actual_build_order)
	end

	def test_one_project
		project("A")
		assert_build_order("A")
	end
	
	def test_two_projects
		project("A")
		project("B")
		assert_build_order("AB")
	end
	
	def test_two_projects_with_dependency
		a = project("A")
		b = project("B")
		b.add_tip_dependency(a)
		assert_build_order("AB")
	end
	
	def test_two_projects_with_reversed_dependency
		a = project("A")
		b = project("B")
		a.add_tip_dependency(b)
		assert_build_order("BA")
	end
	
	def test_three_projects_with_dependencies
		a = project("A")
		b = project("B")
		c = project("C")
		b.add_tip_dependency(a)
		c.add_tip_dependency(b)
		assert_build_order("ABC")
	end
	
	def test_three_projects_with_reversed_dependencies
		a = project("A")
		b = project("B")
		c = project("C")
		b.add_tip_dependency(c)
		a.add_tip_dependency(b)
		assert_build_order("CBA")
	end
end