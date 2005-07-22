require File.dirname(__FILE__) + '/../test_helper'
require 'project_controller'

# Re-raise errors caught by the controller.
class ProjectController; def rescue_action(e) raise e end; end

class ProjectControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProjectController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def Xtest_should_select_scm_on_edit
    scm = RSCM::Subversion.new
    scm.url = "svn://show/this/please"
    project = Project.create(:scm => scm)
    get :edit, :id => project.id
    
    # <option value="RSCM::Perforce">Perforce</option>
    assert_tag :tag => "option", :attributes => {:value => "RSCM::Perforce"}
    assert_tag :tag => "option", :attributes => {:value => "RSCM::Subversion", :selected => "selected"}
    assert_tag :tag => "input", :attributes => {:value => "svn://show/this/please"}
  end

  def test_should_save_scm_and_publishers_on_update
    project = Project.create
    post :update, 
      :id => project.id,
      :project => {
        :name => "Jalla"
      },
      :scm => {
        "RSCM::Subversion" => {
          :selected => true,
          :url => "svn://some/where"
        },
        "RSCM::Cvs" => {
          :selected => false,
          :root => "blah"
        }
      },
      :publisher => {
        "DamageControl::Publisher::Growl" => {
          :enabling_states => ["Build::Successful"],
          :hosts => "codehaus.org"
        },
        "DamageControl::Publisher::Jabber" => {
          :enabling_states => ["Build::Fixed", "Build::Broken"],
          :friends => "aslak@jabber.org"
        }
      }
    
    project.reload
    assert_equal("Jalla", project.name)
    assert_equal(RSCM::Subversion, project.scm.class)
    assert_equal("svn://some/where", project.scm.url)
    
    growl = project.publishers.find{|p| p.class == DamageControl::Publisher::Growl}
    jabber = project.publishers.find{|p| p.class == DamageControl::Publisher::Jabber}

    assert_equal("codehaus.org", growl.hosts)
    assert_equal("aslak@jabber.org", jabber.friends)
  end
end
