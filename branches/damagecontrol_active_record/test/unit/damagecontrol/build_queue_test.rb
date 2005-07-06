require File.dirname(__FILE__) + '/../../test_helper'

module DamageControl
  class BuildQueueTest < Test::Unit::TestCase
    fixtures :projects, :revisions, :builds

    def test_should_block_on_next_until_build_available
      build = @project_2.revisions[0].builds.create(:reason => ::Build::SCM_POLLED)

      bq = BuildQueue.new
      timeout(3, Exception.new("nothing here")) do
        assert_equal(build, bq.next)
      end
    end

  end
end