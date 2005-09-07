require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :revisions, :builds

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
    assert_equal(@build_1, @project_1.builds(:before => Time.utc(1971,02,28,23,45,01))[0])
  end

  def test_should_find_latest_successful_build
    assert_equal(@build_1, @project_1.builds(:exitstatus => 0)[0])
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
    # TODO: fix this nil!
    rf = MetaProject::Tracker::XForge::RubyForgeTracker.new("http://rubyforge.org/tracker/?group_id=801", nil)

    @project_1.tracker = rf
    @project_1.save
    @project_1.reload

    assert_equal("http://rubyforge.org/tracker/?group_id=801", @project_1.tracker.overview)
    assert_equal(true, @project_1.tracker.enabled)
  end

  def test_should_persist_scm_web
    scm_web = MetaProject::ScmWeb::Browser.new(
      "dir/\#{path}", 
      "history/\#{path}", 
      "raw/\#{path}/\#{revision}", 
      "html/\#{path}\#{revision}", 
      "diff/\#{path}\#{revision}", 
      "f", 
      "g"
    )

    @project_1.scm_web = scm_web
    @project_1.save
    @project_1.reload

    assert_equal("dir/foo", @project_1.scm_web.dir("foo"))
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
  
  # fred   ->    wilma
  #  +-> barney <-+
  def FIXMEtest_should_find_dependencies_and_dependants
    fred = Project.create(:name => "fred")
    barney = Project.create(:name => "barney")
    wilma = Project.create(:name => "wilma")
    
    fred.dependencies.add(wilma)
    fred.dependencies.add(barney)
    wilma.dependencies.add(barney)
    
    assert_equal([barney, wilma], fred.dependencies)
    assert_equal([], barney.dependencies)
    assert_equal([barney], wilma.dependencies)

    assert_equal([], fred.dependants)
    assert_equal([fred, wilma], barney.dependants)
    assert_equal([fred], wilma.dependants)
    
    wilma.destroy

    assert_equal([barney], fred.dependencies)
    assert_equal([], barney.dependencies)

    assert_equal([], fred.dependants)
    assert_equal([fred], barney.dependants)
    
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
  
  def test_should_lock_project
    p = Project.create(:name => "lock me")
    assert !p.lock_time
    p.lock_time = Time.now.utc
    assert p.lock_time
  end
  
  def test_should_have_next_pending_build
    assert_nil @project_1.next_pending_build
    pending = @revision_3.request_build(Build::SCM_POLLED)
    assert_equal(pending, @project_1.next_pending_build)
  end
  
end
