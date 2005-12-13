require File.dirname(__FILE__) + '/../../../test_helper'
require 'stringio'

module DamageControl  
  module Process
    class BuilderTest < Test::Unit::TestCase

      def test_should_execute_requested_builds
        builder = Builder.new      
        project = projects(:project_1)

        # nothing should have happened yet
        builder.execute_requested_builds_for(project)
        assert_equal(2, project.builds(:count => 5).length)
        assert_equal(0, project.pending_builds.length)

        revisions(:revision_1).request_builds("Testing")
        assert_equal(3, project.builds(:count => 5).length)
        assert_equal(1, project.pending_builds.length)

        # this should execute a build
        assert !File.exist?("#{project.build_dir}/built")
        builder.execute_requested_builds_for(project)
        assert_equal(3, project.builds(:count => 5).length)
        assert_equal(0, project.pending_builds.length)

        build = project.latest_build
        stderr = File.open(build.stderr_file).read
        stdout = File.open(build.stdout_file).read
        assert(build.successful?, "STDERR:#{stderr}\nSTDOUT:#{stdout}")
        assert File.exist?("#{project.build_dir}/built")
      end

    end
  end
end