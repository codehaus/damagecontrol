require File.dirname(__FILE__) + '/../test_helper'

class BuildTest < Test::Unit::TestCase
  fixtures :builds, :revisions, :projects, :artifacts

  def test_should_create
    br = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    assert_equal(@revision_1, br.revision)
  end
  
  def test_should_not_allow_reexecution
    assert_raise RuntimeError do
      @build_1.execute!
    end
  end
  
  def test_should_execute_in_project_build_dir
    build_proof = "#{DAMAGECONTROL_HOME}/projects/#{@project_1.id}/working_copy/build_here/built"
    File.delete build_proof if File.exist?(build_proof)
    
    build = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    assert(!File.exist?(build_proof), "Should not exist: #{build_proof}")
    assert_equal(0, build.execute!)
    assert_equal(Build::Successful, build.state.class)
    assert(File.exist?(build_proof), "Should exist: #{build_proof}")
  end

  def test_should_persist_build_info
    @project_1.build_command = "echo hello $DAMAGECONTROL_BUILD_LABEL"
    @project_1.save
    build = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    t = Time.now.utc
    assert_equal(0, build.execute!(t))
    build.reload
    
    assert_equal("echo hello $DAMAGECONTROL_BUILD_LABEL", build.command)
    assert_equal("hello xyz\n", build.stdout)
    assert_equal("", build.stderr)
    assert_equal(0, build.exitstatus)
    assert_equal(Build::Successful, build.state.class)
    assert(build.pid)
    assert(0 < build.pid)
    assert_equal(Time, build.timepoint.class)
    assert(build.timepoint.utc?)
    assert_equal(t.to_s, build.timepoint.to_s)
    assert_equal(Build::Successful, build.state.class)
  end

  def test_should_store_info_for_nonexistant_command
    @project_1.build_command = "w_t_f"
    @project_1.save
    build = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    assert_equal(127, build.execute!)
    assert_equal(Build::Broken, build.state.class)
    assert_equal("", build.stdout)
    assert_equal("sh: line 1: w_t_f: command not found\n", build.stderr)
  end

  def test_should_return_one_when_executing_nonexistant_svn_command
    @project_1.build_command = "svn wtf"
    @project_1.save
    build = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    assert_equal(1, build.execute!)
    assert_equal(Build::Broken, build.state.class)
    assert_equal("", build.stdout)
    assert_equal("Unknown command: 'wtf'\nType 'svn help' for usage.\n", build.stderr)
  end
  
  def test_should_not_have_status_after_create
    build = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    assert_nil(build.state)
  end
  
  def test_should_have_artifacts
    assert_equal([@artifact_1, @artifact_2], @build_1.artifacts)
  end
  
  def test_should_save_status_based_on_previous
    p = Project.create
    r = p.revisions.create
    
    b1 = r.builds.create(:exitstatus => 0, :reason => Build::SCM_POLLED)
    b1.determine_state
    b1.save
    assert_equal(Build::Successful, b1.state.class)

    b2 = r.builds.create(:exitstatus => 0, :reason => Build::SCM_POLLED)
    b2.determine_state
    b2.save
    assert_equal(Build::Successful, b2.state.class)

    b3 = r.builds.create(:exitstatus => 1, :reason => Build::SCM_POLLED)
    b3.determine_state
    b3.save
    assert_equal(Build::Broken, b3.state.class)

    b4 = r.builds.create(:exitstatus => 1, :reason => Build::SCM_POLLED)
    b4.determine_state
    b4.save
    assert_equal(Build::RepeatedlyBroken, b4.state.class)

    b5 = r.builds.create(:exitstatus => 0, :reason => Build::SCM_POLLED)
    b5.determine_state
    b5.save
    assert_equal(Build::Fixed, b5.state.class)
    
    b6 = r.builds.create(:exitstatus => 0, :reason => Build::SCM_POLLED)
    b6.determine_state
    b6.save
    assert_equal(Build::Successful, b6.state.class)
  end
  
  def test_should_have_proper_successful_description
    b = @revision_1.builds.create(:state => Build::Successful.new, :reason => Build::SCM_POLLED)
    b.reload
    assert_equal("Successful", b.state.description)
  end

  def test_should_have_proper_fixed_description
    b = @revision_1.builds.create(:state => Build::Fixed.new, :reason => Build::SCM_POLLED)
    b.reload
    assert_equal("Fixed", b.state.description)
  end

  def test_should_have_proper_broken_description
    b = @revision_1.builds.create(:state => Build::Broken.new, :reason => Build::SCM_POLLED)
    b.reload
    assert_equal("Broken", b.state.description)
  end

  def test_should_have_proper_repeatedly_description
    b = @revision_1.builds.create(:state => Build::RepeatedlyBroken.new, :reason => Build::SCM_POLLED)
    b.reload
    assert_equal("Repeatedly broken", b.state.description)
  end
  
  def test_should_report_committer_when_reason_is_polled
    b = @revision_1.builds.create(:reason => Build::SCM_POLLED)
    b.reload
    assert_equal("Commit by aslak", b.reason_description)
  end
end
