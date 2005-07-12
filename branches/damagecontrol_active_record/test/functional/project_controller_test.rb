require File.dirname(__FILE__) + '/../test_helper'
require 'project_controller'

# Re-raise errors caught by the controller.
class ProjectController; def rescue_action(e) raise e end; end

class ProjectControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProjectController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  def test_should_select_scm_on_edit
    scm = RSCM::Subversion.new
    scm.url = "svn://show/this/please"
    project = Project.create(:scm => scm)
    get :edit, :id => project.id
    
    # <option value="RSCM::Perforce">Perforce</option>
    assert_tag :tag => "option", :attributes => {:value => "RSCM::Perforce"}
    assert_tag :tag => "option", :attributes => {:value => "RSCM::Subversion", :selected => "selected"}
    assert_tag :tag => "input", :attributes => {:value => "svn://show/this/please"}
  end

  def test_should_save_scm_on_update
    project = Project.create
    post :update, 
      :id => project.id,
      :project => {:name => "Jalla"},
      :scm => "RSCM::Subversion",
      :scms => {
        "RSCM::Subversion" => {:url => "svn://some/where"}
      }
    
    project.reload
    assert_equal("Jalla", project.name)
    assert_equal(RSCM::Subversion, project.scm.class)
    assert_equal("svn://some/where", project.scm.url)
  end
end
