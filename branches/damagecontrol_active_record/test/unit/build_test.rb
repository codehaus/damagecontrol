require File.dirname(__FILE__) + '/../test_helper'

class BuildTest < Test::Unit::TestCase
  fixtures :builds, :revisions, :projects
# doesn't coexist well with RoR!!
# include MockIt

  def test_should_create
    br = @revision_1.builds.create(
      :reason => "parce que je le vaut bien"
    )
    assert_equal(@revision_1, br.revision)
  end
  
  def test_should_not_allow_reexecution
    assert_raise RuntimeError do
      @build_1.execute!({})
    end
  end
  
  def test_should_execute_in_project_build_dir
    build_proof = ENV["DC_ROOT"] + "/projects/#{@project_1.id}/working_copy/build_here/built"
    build = @revision_1.builds.create
    assert(!File.exist?(build_proof), "Should not exist: #{build_proof}")
    assert_equal(0, build.execute!({}))
    assert(File.exist?(build_proof), "Should exist: #{build_proof}")
  end

  def test_should_persist_build_info
    @project_1.build_command = "echo hello $DC_TEST"
    @project_1.save
    build = @revision_1.builds.create
    t = Time.now.utc
    assert_equal(0, build.execute!({'DC_TEST' => 'world'}, t))
    build.reload
    
    assert_equal("hello world\n", build.stdout)
    assert_equal("", build.stderr)
    assert_equal({'DC_TEST' => 'world'}, build.env)
    assert_equal("echo hello $DC_TEST", build.command)
    assert_equal(0, build.exitstatus)
    assert(build.pid)
    assert(0 < build.pid)
    assert_equal(t, build.timepoint)
    assert_equal("COMPLETE", build.status)
  end

  def test_should_store_info_for_nonexistant_command
    @project_1.build_command = "w_t_f"
    @project_1.save
    build = @revision_1.builds.create
    assert_equal(127, build.execute!({}))
    assert_equal("", build.stdout)
    assert_equal("sh: line 1: w_t_f: command not found\n", build.stderr)
  end

  def test_should_return_one_when_executing_nonexistant_svn_command
    @project_1.build_command = "svn wtf"
    @project_1.save
    build = @revision_1.builds.create
    assert_equal(1, build.execute!({}))
    assert_equal("", build.stdout)
    assert_equal("Unknown command: 'wtf'\nType 'svn help' for usage.\n", build.stderr)
  end
  
  def test_should_initialise_new_build_status_to_requested
    build = @revision_1.builds.create
    assert_equal(Build::REQUESTED, build.status)
  end
end
