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
		@projects.push(project)
		project
	end
end

class AllTraverser
	def traverse(dependency_graph)
		@projects = dependency_graph.projects
		project = next_buildable_project()
		yield project
		@projects.each {|project| yield project}
	end
	
	def next_buildable_project
		project = @projects.find {|project| project.dependencies.empty?}
		@projects.delete(project)
		project
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
end