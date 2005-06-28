require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/builder'
require 'damagecontrol/build_queue'

module DamageControl
  class BuilderTest < Test::Unit::TestCase
    include MockIt
  
    def test_builds_request_from_queue_and_requests_build_for_dependent_projects
      # Warning! This test is very unreadable. Too many mocks!

      project = new_mock
      revision = new_mock
      dependant_latest_revision = new_mock
      dependant_project = new_mock
        
      dependant_project.__expect(:depends_directly_on?) do |p|
        assert_same(project, p)
        true
      end
      dependant_project.__expect(:latest_revision) do
        dependant_latest_revision
      end

      revision.__expect(:project) do
        project
      end
      revision.__expect(:build!) do |reasons|
        assert_equal(["just", "because"], reasons)
        build = new_mock.__expect(:successful?) {true}
        build
      end

      project.__expect(:latest_revision) do
        revision
      end
      project.__expect(:name) do
        "Mooky"
      end
      
      project_finder = new_mock.__expect(:find_all) do |projects_dir|
        assert_equal("some_dir", projects_dir)
        [dependant_project]
      end

      queue = new_mock
      builder = Builder.new(queue, "some_dir", project_finder)

      req = new_mock.__expect(:revision) do
        revision
      end

      queue.__expect(:pop) do |balder|
        assert_same(builder, balder)
        req.__expect(:reasons) do
          ["just", "because"]
        end
      end

      queue.__expect(:enqueue) do |p, reason|
        assert_equal("Successful build of dependency Mooky", reason)
        assert_same(dependant_latest_revision, p)
      end

      queue.__expect(:delete) do |request|
        assert_same(req, request)
      end
      
      builder.build_next
    end
  end
end