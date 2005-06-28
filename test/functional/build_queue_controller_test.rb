require File.dirname(__FILE__) + '/../test_helper'
require 'build_queue_controller'

# Re-raise errors caught by the controller.
class BuildQueueController; def rescue_action(e) raise e end; end

class BuildQueueControllerTest < Test::Unit::TestCase
  def setup
    @controller = BuildQueueController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
