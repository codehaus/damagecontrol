require File.dirname(__FILE__) + '/../test_helper'
require 'scm_controller'

# Re-raise errors caught by the controller.
class ScmController; def rescue_action(e) raise e end; end

class ScmControllerTest < Test::Unit::TestCase
  def setup
    @controller = ScmController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_load_all_scms_on_list
    get :list
    assert(assigns["scms"].length > 0)
  end
end
