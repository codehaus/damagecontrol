require File.dirname(__FILE__) + '/../../test_helper'

module DamageControl
  class BuildQueueTest < Test::Unit::TestCase
    fixtures :projects, :revisions, :builds

    def test_should_build_all_requested_builds
      build = @project_2.revisions[0].builds.create(:reason => ::Build::SCM_POLLED)

      bq = BuildQueue.new
      timeout(3) do
        assert_equal(build, bq.next)
      end
    end

    def test_should_block_on_next_until_build_available
      next_build = nil
    
      bq = BuildQueue.new
      t1 = Thread.new do
        timeout(3) do
          next_build = bq.next
        end
      end
      sleep(1)
      b = ::Build.create(:reason => ::Build::SCM_POLLED)
      t1.join
    
      assert_equal(b, next_build)
    end
  end
end