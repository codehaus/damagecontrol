require File.dirname(__FILE__) + '/../test_helper'
require 'project_controller'

# Re-raise errors caught by the controller.
class ProjectController; def rescue_action(e) raise e end; end

class ProjectControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProjectController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  def test_should_load_scms_on_view
    get :view
  end
end
