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

  def test_truth
  end
end
