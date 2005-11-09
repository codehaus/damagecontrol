require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :projects, :revisions, :builds, :build_executors, :build_executors_projects

  def test_should_have_revisions
    assert_equal(3, projects(:project_1).revisions.length)
  end
  
  def test_should_find_latest_revision
    assert_equal(revisions(:revision_3), projects(:project_1).latest_revision)
  end

  def test_should_find_latest_build_based_on_create_time
    assert_equal(builds(:build_2), projects(:project_1).latest_build)
  end

  def test_should_find_latest_build_before
    assert_equal(builds(:build_2), projects(:project_1).builds(:before => Time.utc(1971,02,28,23,41,02))[0])
    assert_equal(builds(:build_1), projects(:project_1).builds(:before => Time.utc(1971,02,28,23,41,01))[0])
  end

  def test_should_find_latest_successful_build
    assert_equal(builds(:build_1), projects(:project_1).latest_successful_build)
  end
  
  def test_should_have_build_executors
    assert_equal([build_executors(:slave_1), build_executors(:slave_2)], projects(:slave_project).build_executors)
  end

  def test_should_persist_scm
    cvs = RSCM::Cvs.new("a_root", "a_mod", "a_branch", "a_password")

    projects(:project_1).scm = cvs
    projects(:project_1).save
    projects(:project_1).reload

    assert_equal(cvs, projects(:project_1).scm)

    projects(:project_1).scm.root = "jalla"
    projects(:project_1).save
    projects(:project_1).reload
    assert_equal("jalla", projects(:project_1).scm.root)
    assert_equal(true, projects(:project_1).scm.enabled)
  end

  def test_should_persist_tracker
    # TODO: fix this nil!
    rf = MetaProject::Tracker::XForge::RubyForgeTracker.new("http://rubyforge.org/tracker/?group_id=801", nil)

    projects(:project_1).tracker = rf
    projects(:project_1).save
    projects(:project_1).reload

    assert_equal("http://rubyforge.org/tracker/?group_id=801", projects(:project_1).tracker.overview)
    assert_equal(true, projects(:project_1).tracker.enabled)
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

    projects(:project_1).scm_web = scm_web
    projects(:project_1).save
    projects(:project_1).reload

    assert_equal("dir/foo", projects(:project_1).scm_web.dir("foo"))
    assert_equal(true, projects(:project_1).scm_web.enabled)
  end

  def test_should_persist_publishers
    publishers = DamageControl::Publisher::Base.classes.collect{|cls| cls.new}
    projects(:project_1).publishers = publishers
    projects(:project_1).save
    project_1_found = Project.find(projects(:project_1).id)
    assert_not_same(projects(:project_1), project_1_found)

    assert_equal(DamageControl::Publisher::Base.classes, project_1_found.publishers.collect{|pub| pub.class})
  end

  def test_should_create_basedir_after_load
    expected_base_dir = "#{DC_DATA_DIR}/projects/#{projects(:project_1).id}"
    assert(File.exist?(expected_base_dir), "Should exist: #{expected_base_dir}")
  end

  # fred   ->    wilma -> dino
  #  +-> barney <-+
  def test_should_find_dependencies_and_dependants
    fred = Project.create(:name => "fred")
    barney = Project.create(:name => "barney")
    dino = Project.create(:name => "dino")
    wilma = Project.create(:name => "wilma")
    
    fred.dependencies << wilma
    fred.dependencies << barney
    wilma.dependencies << barney
    wilma.dependencies << dino
    
    fred.reload
    barney.reload
    dino.reload
    wilma.reload
    
    assert_equal([], barney.dependencies)
    assert_equal([barney, wilma], fred.dependencies)
    assert_equal([], dino.dependencies)
    assert_equal([barney, dino], wilma.dependencies)
    
    assert fred.could_depend_on?(wilma)
    assert !wilma.could_depend_on?(fred)
    assert fred.could_depend_on?(dino)
    assert !dino.could_depend_on?(fred)

    assert_equal([fred, wilma], barney.dependants)
    assert_equal([], fred.dependants)
    assert_equal([wilma], dino.dependants)
    assert_equal([fred], wilma.dependants)
    
    wilma.destroy
    barney.reload
    dino.reload
    fred.reload

    assert_equal([], barney.dependencies)
    assert_equal([barney], fred.dependencies)
    assert_equal([], dino.dependencies)

    assert_equal([fred], barney.dependants)
    assert_equal([], fred.dependants)
    assert_equal([], dino.dependants)
    
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
  
  def test_should_lock_project
    p = Project.create(:name => "lock me")
    assert !p.lock_time
    p.lock_time = Time.now.utc
    assert p.lock_time
  end
  
  def test_should_have_latest_pending_builds
    assert_equal([], projects(:project_1).pending_builds)
    pending = revisions(:revision_3).request_builds(Build::SCM_POLLED)
    assert_equal(pending, projects(:project_1).pending_builds)
  end
  
  def FIXMEtest_should_import_and_export_as_yaml
    import = YAML.load_file(File.dirname(__FILE__) + '/../../damagecontrol.yml')
    p = Project.new
    p.populate_from_hash(import)
    assert_equal("http://damagecontrol.codehaus.org/", p.home_page)
    export = p.export_to_hash
    assert_equal(import, export)
  end
  
end
