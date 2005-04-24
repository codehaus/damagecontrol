require 'test/unit'
require 'yaml'
require 'rscm'
require 'rscm/tempdir'
require 'rscm/mockit'
require 'damagecontrol/build'
require 'damagecontrol/revision_ext'

module RSCM
  class RevisionExtTest < Test::Unit::TestCase
    include MockIt
  
    def test_should_not_dump_project_in_yaml
      revision = Revision.new
      YAML::dump(revision)
      revision.project = "foo"
      revision = YAML::load(YAML::dump(revision))
      assert_nil(revision.project)
    end

    def test_should_checkout_from_revision_identifier_and_execute_build
      project_dir = RSCM.new_temp_dir("RevisionExtTest1")
      p = DamageControl::Project.new
      p.dir = project_dir
      p.scm = new_mock.__expect(:checkout)
      execute_dir = p.dir + "/foo"
      p.scm.__expect(:checkout_dir) {execute_dir}
      p.build_command = "some command"

      c = Revision.new
      c.revision = "some_id"
      c.project = p
      
      before = Time.new
      c.build!("Testing") do |build|
        now = Time.new
        assert(before <= build.time)
        assert(build.time <= now)
        assert_equal("some command", File.open("#{project_dir}/revisions/some_id/builds/#{build.time.to_s}/command").read)
        assert(!build.successful?)
      end
    end
    
    def test_should_load_persisted_builds_that_are_frozen
      project_dir = RSCM.new_temp_dir("RevisionExtTest2")
      p = DamageControl::Project.new
      p.dir = project_dir

      c = Revision.new
      c.revision = "some_id"
      c.project = p

      now = Time.new.utc
      build_1_time = now + 10
      build_2_time = now + 20
      FileUtils.mkdir_p("#{project_dir}/revisions/some_id/builds/#{build_1_time.ymdHMS}")
      FileUtils.touch("#{project_dir}/revisions/some_id/builds/#{build_1_time.ymdHMS}/command")
      FileUtils.touch("#{project_dir}/revisions/some_id/builds/#{build_1_time.ymdHMS}/reason")

      FileUtils.mkdir_p("#{project_dir}/revisions/some_id/builds/#{build_2_time.ymdHMS}")
      FileUtils.touch("#{project_dir}/revisions/some_id/builds/#{build_2_time.ymdHMS}/reason")

      builds = c.builds
      assert_equal(2, builds.length)
      assert_equal(build_1_time, builds[0].time)
      assert_equal(build_2_time, builds[1].time)
      assert_raises(DamageControl::BuildException, "shouldn't be able to execute persisted build") do
        builds[0].execute("this should fail because command file exists", nil, nil)
      end
      builds[1].execute("echo \"this should pass since command file doesn't exist\"", p.dir, {})
      assert_raises(DamageControl::BuildException, "shouldn't be able to execute persisted build") do
        builds[1].execute("this should fail because command file exists", p.dir, nil)
      end
    end
    
  end
end