module TraverserTestHelper
 	def setup
 		@graph = DependencyGraph.new
	end

	def project(name)
		@graph.add_project(name)
	end
	
	def assert_build_order(expected_build_order)
		actual_build_order = ""
		traverser = create_traverser()
		traverser.traverse(@graph)  {|project| actual_build_order += project.name}
		assert_equal(expected_build_order, actual_build_order)
	end
end