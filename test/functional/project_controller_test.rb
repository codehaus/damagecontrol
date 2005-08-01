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

  def test_should_save_plugins_on_update
    project = Project.create
    post :update, 
      :id => project.id,
      :project => {
        :name => "Jalla"
      },
      :scm => {
        "RSCM::Subversion" => {
          :enabled => true,
          :url => "svn://some/where"
        },
        "RSCM::Cvs" => {
          :enabled => false,
          :root => "blah"
        }
      },
      :tracker => {
        "DamageControl::Tracker::Bugzilla" => {
          :enabled => false,
          :url => "http://bugzilla.org/bugs"
        },
        "DamageControl::Tracker::Jira" => {
          :enabled => true,
          :baseurl => "http://jira.codehaus.org/"
        }
      },
      :scm_web => {
        "DamageControl::ScmWeb::Trac" => {
          :enabled => true,
          :changeset_url => "http://trac.org/changesets"
        },
        "DamageControl::ScmWeb::Chora" => {
          :enabled => false
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
    
    assert_equal(DamageControl::Tracker::Jira, project.tracker.class)
    assert_equal("http://jira.codehaus.org/", project.tracker.baseurl)

    assert_equal(DamageControl::ScmWeb::Trac, project.scm_web.class)
    assert_equal("http://trac.org/changesets", project.scm_web.changeset_url)

    growl = project.publishers.find{|p| p.class == DamageControl::Publisher::Growl}
    assert_equal("codehaus.org", growl.hosts)
    jabber = project.publishers.find{|p| p.class == DamageControl::Publisher::Jabber}
    assert_equal("aslak@jabber.org", jabber.friends)
  end
end
