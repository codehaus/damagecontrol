require 'test/unit'

module DamageControl
	class BuildTest < Test::Unit::TestCase
		def test_is_log_file
			@build = Build.new("project_name", nil, nil)
			assert(!@build.log_file?("."), ". is not a log file")
			assert(@build.log_file?("1.log"), "1.log is a log file")
		end
	end
end	