require File.dirname(__FILE__) + '/../test_helper'

class BuildExecutorTest < Test::Unit::TestCase
  fixtures :build_executors, :revisions, :builds, :build_executors

  def test_should_have_builds
    assert_equal([@build_2], @slave_2.builds)
    
    @slave_2.builds << @build_1
    assert_equal([@build_1, @build_2], @slave_2.builds(true))
  end
  
  def test_should_request_builds
    p = Project.create
    be = BuildExecutor.create
    r = Revision.create(RSCM::Revision.new)
    p.revisions << r
    b = be.request_build_for(r, Build::SCM_POLLED, nil)
    
    be.reload
    r.reload
    b.reload
    
    assert_equal([b], r.builds)
    assert_equal([b], be.builds)
  end
end
