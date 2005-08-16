require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :revisions, :builds, :projects_projects

  def test_should_have_revisions
    assert_equal(3, @project_1.revisions.length)
  end
  
  def test_should_find_latest_revision
    assert_equal(@revision_3, @project_1.latest_revision)
  end
  
  def test_should_find_latest_build
    assert_equal(@build_2, @project_1.builds[0])
  end

  def test_should_find_latest_build_before
    assert_equal(@build_1, @project_1.builds(nil, Time.utc(1971,02,28,23,45,01))[0])
  end

  def test_should_find_latest_successful_build
    assert_equal(@build_1, @project_1.builds(true)[0])
  end

  def test_should_persist_scm
    cvs = RSCM::Cvs.new("a_root", "a_mod", "a_branch", "a_password")

    @project_1.scm = cvs
    @project_1.save
    @project_1.reload

    assert_equal(cvs, @project_1.scm)

    @project_1.scm.root = "jalla"
    @project_1.save
    @project_1.reload
    assert_equal("jalla", @project_1.scm.root)
    assert_equal(true, @project_1.scm.enabled)
  end

  def test_should_persist_tracker
    jira = DamageControl::Tracker::Jira.new

    @project_1.tracker = jira
    @project_1.save
    @project_1.reload

    @project_1.tracker.baseurl = "jalla"
    @project_1.save
    @project_1.reload
    assert_equal("jalla", @project_1.tracker.baseurl)
    assert_equal(true, @project_1.tracker.enabled)
  end

  def test_should_persist_scm_web
    view_cvs = DamageControl::ScmWeb::ViewCvs.new

    @project_1.scm_web = view_cvs
    @project_1.save
    @project_1.reload

    @project_1.scm_web.baseurl = "jalla"
    @project_1.save
    @project_1.reload
    assert_equal("jalla", @project_1.scm_web.baseurl)
    assert_equal(true, @project_1.scm_web.enabled)
  end

  def test_should_persist_publishers
    publishers = DamageControl::Publisher::Base.classes.collect{|cls| cls.new}
    @project_1.publishers = publishers
    @project_1.save
    @project_1_found = Project.find(@project_1.id)
    assert_not_same(@project_1, @project_1_found)

    assert_equal(DamageControl::Publisher::Base.classes, @project_1_found.publishers.collect{|pub| pub.class})
  end

  def test_should_create_basedir_after_load
    expected_base_dir = "#{DAMAGECONTROL_HOME}/projects/#{@project_1.id}"
    assert(File.exist?(expected_base_dir), "Should exist: #{expected_base_dir}")
  end

  def test_should_initialise_scm_checkout_dir_on_find
    @project_1.scm = RSCM::Cvs.new("a_root", "a_mod", "a_branch", "a_password")
    @project_1.save
    @project_1.reload

    expected_wc_dir = "#{DAMAGECONTROL_HOME}/projects/#{@project_1.id}/working_copy"
    assert(File.exist?(expected_wc_dir), "Should exist: #{expected_wc_dir}")
    assert_equal(@project_1.working_copy_dir, @project_1.scm.checkout_dir)
  end
  
  def test_should_find_dependencies
    assert_equal([@project_1, @project_2], @project_3.dependencies)
  end

  def test_should_find_dependants
    assert_equal([@project_3], @project_1.dependants)
    assert_equal([@project_3], @project_2.dependants)
  end
  
  def FIXMEtest_should_create_rgl_graph
    graph = Project.dependency_graph
    assert_equal(2, graph.edges.size)
    assert_equal(3, graph.vertices.size)
  end
  
  def FIXMEtest_should_calculate_sub_graphs
    fred = Project.create(:name => "fred")
    wilma = Project.create(:name => "wilma")
    fred.dependencies << wilma
    fred.save

    graph = Project.dependency_graph
    assert_equal(3, graph.edges.size)
    assert_equal(5, graph.vertices.size)
    
    # TODO: how the heck do we get the 2 sub graphs?
  end
  
  def test_should_create_pending_build_for_latest_revision
    assert_equal(0, @revision_3.builds.size)
    @project_1.request_build(Build::SUCCESSFUL_DEPENDENCY)
    assert_equal(1, @revision_3.builds(true).size)
    assert_equal(Build::SUCCESSFUL_DEPENDENCY, @revision_3.builds[0].reason)
  end
  
end
