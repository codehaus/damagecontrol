require File.dirname(__FILE__) + '/../test_helper'
require 'rscm/mockit'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :revisions, :projects_projects, :publishers

  def test_should_have_revisions
    assert_equal(3, @project_1.revisions.length)
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
  end
  
  def test_should_create_basedir_after_load
    expected_base_dir = ENV["DAMAGECONTROL_HOME"] + "/projects/#{@project_1.id}"
    assert(File.exist?(expected_base_dir), "Should exist: #{expected_base_dir}")
  end

  def test_should_initialise_scm_checkout_dir_on_find
    @project_1.scm = RSCM::Cvs.new("a_root", "a_mod", "a_branch", "a_password")
    @project_1.save
    @project_1.reload

    expected_wc_dir = ENV["DAMAGECONTROL_HOME"] + "/projects/#{@project_1.id}/working_copy"
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
  
  def test_should_have_publishers
    assert_equal([@publisher_1], @project_1.publishers)
  end
  
  def test_should_create_rgl_graph
    graph = Project.dependency_graph
    assert_equal(2, graph.edges.size)
    assert_equal(3, graph.vertices.size)
  end
  
  def test_should_calculate_sub_graphs
    fred = Project.create(:name => "fred")
    wilma = Project.create(:name => "wilma")
    fred.dependencies << wilma
    fred.save

    graph = Project.dependency_graph
    assert_equal(3, graph.edges.size)
    assert_equal(5, graph.vertices.size)
    
    # TODO: how the heck do we get the 2 sub graphs?
  end
  
  def test_should_create_requested_build_for_latest_revision
    assert_equal(0, @revision_3.builds.size)
    @project_1.create_build_request("testing")
    assert_equal(1, @revision_3.builds.size)
    assert_equal("testing", @revision_3.builds[0].reason)
  end

end
