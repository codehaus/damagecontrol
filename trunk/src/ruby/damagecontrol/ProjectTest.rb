require 'test/unit'

module DamageControl
	class ProjectTest < Test::Unit::TestCase
		def test_is_log_file
			@project = Project.new("project_name")
			assert(!@project.is_log_file("."), ". is not a log file")
			assert(@project.is_log_file("1.log"), "1.log is a log file")
		end
	end
end	