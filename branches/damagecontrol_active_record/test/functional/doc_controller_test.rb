require File.dirname(__FILE__) + '/../test_helper'
require 'doc_controller'

# Re-raise errors caught by the controller.
class DocController; def rescue_action(e) raise e end; end

class DocControllerTest < Test::Unit::TestCase
  def setup
    @controller = DocController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
