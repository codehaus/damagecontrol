require 'test/unit'

module DamageControl
	class BuildTest < Test::Unit::TestCase
		def test_is_log_file
			@build = Build.new("project_name")
			assert(!@build.is_log_file("."), ". is not a log file")
			assert(@build.is_log_file("1.log"), "1.log is a log file")
		end
	end
end	