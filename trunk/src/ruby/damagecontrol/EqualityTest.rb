require 'test/unit'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'

module DamageControl
	class EqualityTest < Test::Unit::TestCase
		def test_build
			do_test_same {
				Build.new("name")
			}
		end
		
		def test_build_complete_event
			build = Build.new("name")
			do_test_equal {
				BuildCompleteEvent.new(build)
			}
		end
		
		def test_build_progress_event
			build = Build.new("name")
			do_test_equal {
				BuildProgressEvent.new(build, "output")
			}
		end
		
		def test_build_request_event
			build = Build.new("name")
			do_test_equal {
				BuildProgressEvent.new(build, "output")
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