require 'test/unit'
require 'damagecontrol/AllTraverser'
require 'damagecontrol/TraverserTestHelper'

class AllTraverserTest < Test::Unit::TestCase
	include TraverserTestHelper
	
	def create_traverser
		return AllTraverser.new
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