require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/build_request_poller'

module DamageControl
  class BuildTest < Test::Unit::TestCase
    include MockIt
    
    def test_should_pick_up_build_request_from_request_dir_and_enque_in_build_queue
      build_queue = new_mock
      
      build_queue.__expect(:enqueue) do |revision, reason|
        assert_equal("dummy_revision", revision)
        assert_equal("huba luba", reason)
      end

      basedir = RSCM.new_temp_dir("build_request_file")
      FileUtils.mkdir_p("#{basedir}/build_requests")
      File.open("#{basedir}/build_requests/Whatever", 'w') do |io|
        YAML::dump( {:project_name => "Boing", :revision_identifier => "1234", :reason => "huba luba"}, io )
      end

      brp = BuildRequestPoller.new(basedir, build_queue)
      def brp.load_project(project_name)
        extend MockIt
        project = new_mock
        project.__expect(:revision) {
          cs = "dummy_revision"
          def cs.identifier
            "dummy_id"
          end
          cs
        }
      end

      brp.poll
    end
  end
end