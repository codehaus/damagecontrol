require 'test/unit'
require 'damagecontrol/BuildCompleteEvent'
require 'damagecontrol/BuildProgressEvent'
require 'damagecontrol/Project'

module DamageControl
	class EqualityTest < Test::Unit::TestCase
		def test_project
			do_test_same {
				Project.new("name")
			}
		end
		
		def test_build_complete_event
			project = Project.new("name")
			do_test_equal {
				BuildCompleteEvent.new(project)
			}
		end
		
		def test_build_progress_event
			project = Project.new("name")
			do_test_equal {
				BuildProgressEvent.new(project, "output")
			}
		end
		
		def test_build_request_event
			project = Project.new("name")
			do_test_equal {
				BuildProgressEvent.new(project, "output")
			}
		end
				
		def do_test_same
			o = yield
			assert_same(o, o)
		end

		def do_test_equal
			o1 = yield
			o2 = yield
			assert_equal(o1, o2)
		end
	end
end