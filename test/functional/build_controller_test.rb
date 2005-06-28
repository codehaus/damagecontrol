require File.dirname(__FILE__) + '/../test_helper'
require 'build_controller'

# Re-raise errors caught by the controller.
class BuildController; def rescue_action(e) raise e end; end

class BuildControllerTest < Test::Unit::TestCase
  def setup
    @controller = BuildController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
