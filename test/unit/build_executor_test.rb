require File.dirname(__FILE__) + '/../test_helper'

class BuildExecutorTest < Test::Unit::TestCase

  def test_should_have_builds
    assert_equal([builds(:build_2)], build_executors(:slave_2).builds)
    
    build_executors(:slave_2).builds << builds(:build_1)
    assert_equal([builds(:build_1), builds(:build_2)], build_executors(:slave_2).builds(true))
  end
  
  def test_should_request_builds
    n = Project.find(:all).size
    p = Project.create(:name => "p#{n}")
    be = BuildExecutor.create
    r = Revision.create
    p.revisions << r
    b = be.request_build_for(r, Build::SCM_POLLED, nil)
    
    be.reload
    r.reload
    b.reload
    
    assert_equal([b], r.builds)
    assert_equal([b], be.builds)
  end
end
