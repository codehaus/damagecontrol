require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/web/ProjectStatus'

require 'damagecontrol/core/Build'

module DamageControl
  class ProjectStatusTest < Test::Unit::TestCase
    include MockIt

    def test_percentage_done_is_zero_with_no_last_build
      build_history_repository = new_mock
      build_history_repository.__setup(:current_build) { nil }
      ps = ProjectStatus.new("project", build_history_repository)
      assert_equal(0, ps.percentage_done)
    end
    
    def test_can_calculate_percentage_done_and_left
      build_history_repository = new_mock
      build_history_repository.__setup(:last_successful_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.dc_start_time = Time.at(0).utc
        b.duration = 30
        b
      }
      build_history_repository.__setup(:current_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.dc_start_time = Time.at(40).utc
        b
      }
      ps = ProjectStatus.new("project", build_history_repository)
      def ps.current_time
        Time.at(50).utc
      end
      assert_equal(33, ps.percentage_done)
      assert_equal(67, ps.percentage_left)
    end
    
    def test_calculates_percentage_done_from_last_completed_project_if_there_are_no_successful_ones
      build_history_repository = new_mock
      build_history_repository.__setup(:last_successful_build) {|project_name|
        assert_equal("project", project_name)
        nil
      }
      build_history_repository.__setup(:last_completed_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.dc_start_time = Time.at(0).utc
        b.duration = 30
        b
      }
      build_history_repository.__setup(:current_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.dc_start_time = Time.at(40).utc
        b
      }
      ps = ProjectStatus.new("project", build_history_repository)
      def ps.current_time
        Time.at(50).utc
      end
      assert_equal(33, ps.percentage_done)
      assert_equal(67, ps.percentage_left)
    end
    
    def test_is_95_percent_done_if_longer_than_last_build
      build_history_repository = new_mock
      build_history_repository.__setup(:last_successful_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.dc_start_time = Time.at(0).utc
        b.duration = 30
        b
      }
      build_history_repository.__setup(:current_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.dc_start_time = Time.at(40).utc
        b
      }
      ps = ProjectStatus.new("project", build_history_repository)
      def ps.current_time
        Time.at(80).utc
      end
      assert_equal(95, ps.percentage_done)
      assert_equal(5, ps.percentage_left)
    end
    
  end
end