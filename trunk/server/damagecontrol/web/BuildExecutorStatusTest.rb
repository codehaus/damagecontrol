require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/web/BuildExecutorStatus'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'

module DamageControl
  class BuildExecutorStatusTest < Test::Unit::TestCase
    def setup
      @build_executor = MockIt::Mock.new
      @build_history_repository = MockIt::Mock.new
      @status = BuildExecutorStatus.new(0, @build_executor, @build_history_repository)
      @build = Build.new("project")
    end
    
    def teardown
      @build_executor.__verify
      @build_history_repository.__verify
    end
    
    def test_percentage_done_is_zero_with_no_last_build
      @build_history_repository.__setup(:last_successful_build) { nil }
      @build_history_repository.__setup(:last_completed_build) { nil }

      @build_executor.__setup(:scheduled_build) {@build}
      assert_equal(0, @status.percentage_done)
    end
    
    def test_percentage_done_is_zero_with_no_current_build
      @build_executor.__setup(:scheduled_build) {nil}
      assert_equal(0, @status.percentage_done)
    end
    
    def test_can_calculate_percentage_done_and_left
      @build_history_repository.__setup(:last_successful_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.start_time = Time.at(0).utc
        b.end_time = Time.at(30).utc
        b
      }
      @build.start_time = Time.at(40).utc
      def @status.current_time
        Time.at(50).utc
      end
      @build_executor.__setup(:scheduled_build) {@build}
      assert_equal(33, @status.percentage_done)
      assert_equal(67, @status.percentage_left)
    end
    
    def test_calculates_percentage_done_from_last_completed_project_if_there_are_no_successful_ones
      @build_history_repository.__setup(:last_successful_build) {|project_name|
        assert_equal("project", project_name)
        nil
      }
      @build_history_repository.__setup(:last_completed_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.start_time = Time.at(0).utc
        b.end_time = Time.at(30).utc
        b
      }
      @build.start_time = Time.at(40).utc
      @build_executor.__setup(:scheduled_build) {@build}
      def @status.current_time
        Time.at(50).utc
      end
      assert_equal(33, @status.percentage_done)
      assert_equal(67, @status.percentage_left)
    end
    
    def test_is_95_percent_done_if_longer_than_last_build
      @build_history_repository.__setup(:last_successful_build) {|project_name|
        assert_equal("project", project_name)
        b = Build.new
        b.start_time = Time.at(0).utc
        b.end_time = Time.at(30).utc
        b
      }
      @build.start_time = Time.at(40).utc
      @build_executor.__setup(:scheduled_build) {@build}
      def @status.current_time
        Time.at(80).utc
      end
      assert_equal(95, @status.percentage_done)
      assert_equal(5, @status.percentage_left)
    end
    
  end
end