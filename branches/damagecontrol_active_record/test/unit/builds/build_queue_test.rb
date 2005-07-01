require File.dirname(__FILE__) + '/../../test_helper'
require 'rscm/mockit'
require 'damagecontrol'

module DamageControl
  class BuildQueueTest < Test::Unit::TestCase
    fixtures :projects, :revisions, :builds

    def test_should_build_all_requested_builds
      build = @project_2.revisions[0].builds.create
    
      bq = BuildQueue.new
      timeout(3) do
        assert_equal(build, bq.next)
      end
    end
  
    def test_should_inject_object_to_find_requested_builds
      b1 = Build.new
      b2 = Build.new
      builds = [b1, b2]
    
      build_finder = MockIt::Mock.new
      build_finder.__expect(:find_all_by_status) do |status|
        assert_equal(::Build::REQUESTED, status)
        builds
      end
    
      bq = BuildQueue.new(build_finder)
      assert_same(b1, bq.next)
    
      build_finder.__verify
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
      b = ::Build.create
      t1.join
    
      assert_equal(b, next_build)
    end
  end
end