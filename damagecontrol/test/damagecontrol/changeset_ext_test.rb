require 'test/unit'
require 'yaml'
require 'rscm'
require 'rscm/tempdir'
require 'rscm/mockit'
require 'damagecontrol/build'
require 'damagecontrol/changeset_ext'

module RSCM
  class ChangeSetExtTest < Test::Unit::TestCase
    include MockIt
  
    def test_should_not_dump_project_in_yaml
      changeset = ChangeSet.new
      YAML::dump(changeset)
      changeset.project = "foo"
      changeset = YAML::load(YAML::dump(changeset))
      assert_nil(changeset.project)
    end

    def test_should_checkout_from_changeset_identifier_and_execute_build
      project_dir = RSCM.new_temp_dir("ChangeSetExtTest1")
      p = DamageControl::Project.new
      p.dir = project_dir
      p.scm = new_mock.__expect(:checkout)
      p.build_command = "some command"

      c = ChangeSet.new
      c.revision = "some_id"
      c.project = p
      
      before = Time.new
      c.build!(p, "Testing") do |build|
        now = Time.new
        assert(before <= build.time)
        assert(build.time <= now)
        assert_equal("some command", File.open("#{project_dir}/changesets/some_id/builds/#{build.time.to_s}/command").read)
        assert(!build.successful?)
      end
    end
    
    def test_should_load_persisted_builds_that_are_frozen
      project_dir = RSCM.new_temp_dir("ChangeSetExtTest2")
      p = DamageControl::Project.new
      p.dir = project_dir

      c = ChangeSet.new
      c.revision = "some_id"
      c.project = p

      now = Time.new.utc
      build_1_time = now + 10
      build_2_time = now + 20
      FileUtils.mkdir_p("#{project_dir}/changesets/some_id/builds/#{build_1_time.ymdHMS}")
      FileUtils.touch("#{project_dir}/changesets/some_id/builds/#{build_1_time.ymdHMS}/command")
      FileUtils.touch("#{project_dir}/changesets/some_id/builds/#{build_1_time.ymdHMS}/reason")

      FileUtils.mkdir_p("#{project_dir}/changesets/some_id/builds/#{build_2_time.ymdHMS}")
      FileUtils.touch("#{project_dir}/changesets/some_id/builds/#{build_2_time.ymdHMS}/reason")

      builds = c.builds
      assert_equal(2, builds.length)
      assert_equal(build_1_time, builds[0].time)
      assert_equal(build_2_time, builds[1].time)
      assert_raises(DamageControl::BuildException, "shouldn't be able to execute persisted build") do
        builds[0].execute("this should fail because command file exists")
      end
      builds[1].execute("echo \"this should pass since command file doesn't exist\"")
      assert_raises(DamageControl::BuildException, "shouldn't be able to execute persisted build") do
        builds[1].execute("this should fail because command file exists")
      end
    end
    
  end
end