require File.dirname(__FILE__) + '/../test_helper'
require 'revision_controller'

# Re-raise errors caught by the controller.
class RevisionController; def rescue_action(e) raise e end; end

class RevisionControllerTest < Test::Unit::TestCase
  fixtures :revisions, :builds, :projects, :build_executors_projects
  
  def setup
    @controller = RevisionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_create_new_build
    build_count = @revision_1.builds.size
    
    post :build, :id => @revision_1.id, :reason => "test"
    
    @revision_1.reload
    assert_equal(build_count + 1, @revision_1.builds(true).size)
  end
end
