require File.dirname(__FILE__) + '/../test_helper'
require 'project_controller'
require 'damagecontrol'

# Re-raise errors caught by the controller.
class ProjectController; def rescue_action(e) raise e end; end

class ProjectControllerTest < Test::Unit::TestCase
  fixtures :projects, :revisions, :builds, :artifacts
  
  def setup
    @controller = ProjectController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
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
        "MetaProject::Tracker::Trac::TracTracker" => {
          :enabled => false,
          :trac_base_url => "http://dev.rubyonrails.com/"
        },
        "MetaProject::Tracker::Jira::JiraTracker" => {
          :enabled => true,
          :rooturl => "http://jira.codehaus.org/",
          :identifier => "DC"
        }
      },
      :scm_web => {
        :overview_spec => "http://foo.com/overview/", 
        :history_spec => "http://foo.com/history/\#{path}", 
        :raw_spec => "http://foo.com/raw/\#{path}?r=\#{revision}", 
        :html_spec => "http://foo.com/html/\#{path}?r=\#{revision}", 
        :diff_spec => "http://foo.com/diff/\#{path}?r1=\#{previous_revision}&r2=\#{revision}"
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
    
    assert_equal(MetaProject::Tracker::Jira::JiraTracker, project.tracker.class)
    assert_equal("http://jira.codehaus.org/", project.tracker.rooturl)
    assert_equal("DC", project.tracker.identifier)

    assert_equal(MetaProject::ScmWeb, project.scm_web.class)
    assert_equal(
      "http://foo.com/diff/where/is/this.rb?r1=x&r2=y", 
      project.scm_web.diff("where/is/this.rb", "y", "x"))

    growl = project.publishers.find{|p| p.class == DamageControl::Publisher::Growl}
    assert_equal("codehaus.org", growl.hosts)
    jabber = project.publishers.find{|p| p.class == DamageControl::Publisher::Jabber}
    assert_equal("aslak@jabber.org", jabber.friends)
  end

  def test_should_create_revisions_rss
    setup_project_for_rss

    post :revisions_rss, :id => @project_1.id
    # TODO assert something with a trac path here!
    assert @response.body.index("<pubDate>Sun, 28 Feb 1971 23:45:02 -0000</pubDate>")
  end

  def test_should_create_builds_rss
    setup_project_for_rss

    post :builds_rss, :id => @project_1.id
    assert @response.body.index("<enclosure url=\"http://test.host/artifacts/hoppe/sa/gaasa.gem\"") != -1
    assert @response.body.index("length=\"9\"") != 0
    assert @response.body.index("<pubDate>Sun, 28 Feb 1971 23:45:01 -0000</pubDate>")
  end

  def test_should_create_mixed_rss
    setup_project_for_rss

    post :rss, :id => @project_1.id
    assert @response.body.index("<enclosure url=\"http://test.host/artifacts/hoppe/sa/gaasa.gem\"") != -1
    assert @response.body.index("length=\"9\"") != 0
    assert @response.body.index("<pubDate>Sun, 28 Feb 1971 23:45:02 -0000</pubDate>")
  end

private

  def setup_project_for_rss
    trac = MetaProject::Tracker::Trac::TracTracker.new
    trac.trac_base_url = "http://dev.rubyonrails.com/"
    trac.enabled = true
    @project_1.tracker = trac
    @project_1.save

    @artifact_1.file.parent.mkpath
    @artifact_1.file.open("w") {|io| io.puts "a one" }
    @artifact_2.file.parent.mkpath
    @artifact_2.file.open("w") {|io| io.puts "a twoooo" }
  end
end
