require 'test/unit'
require 'damagecontrol/dependency/TraverserTestHelper'

module DamageControl
	module Dependency
		class UpstreamDownstreamTraverser
			def initialize(start_project)
				@start_project = start_project
			end
			
			def traverse(dependency_graph)
				yield dependency_graph.get_project(@start_project)
			end
		end
		
		class UpstreamDownstreamTraverserTest < Test::Unit::TestCase
			include TraverserTestHelper
			
			def create_traverser
				UpstreamDownstreamTraverser.new("START")
			end
			
			def test_one_project
				project("START")
				assert_build_order("START")
			end
		end
	end
end