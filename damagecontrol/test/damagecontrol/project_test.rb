require 'test/unit'
require 'rscm/tempdir'
require 'rscm/mockit'
require 'rscm/changes'
require 'damagecontrol/project'

module DamageControl
  class ProjectTest < Test::Unit::TestCase
    include MockIt
    
    def setup
      MockIt::setup
      @p = Project.new
      @p.description = "bla bla"
      @p.name = "blabla"
    end
    
    def test_poll_should_get_changesets_from_epoch_if_last_change_time_unknown
      ENV["DAMAGECONTROL_HOME"] = RSCM.new_temp_dir("epoch")
      @p.scm = new_mock
      changesets = new_mock
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(Time.epoch, from)
        changesets
      end
      @p.scm.__expect(:transactional?) {true}
      @p.poll do |cs|
        assert_equal(changesets, cs)
      end
    end

    def test_poll_should_poll_until_quiet_period_elapsed
      ENV["DAMAGECONTROL_HOME"] = RSCM.new_temp_dir("quiet_period")

      @p.quiet_period = 0
      @p.scm = new_mock
      @p.scm.__setup(:name) {"mooky"}
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(Time.epoch, from)
        "foo"
      end
      @p.scm.__expect(:transactional?) {false}
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(Time.epoch, from)
        "bar"
      end
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(Time.epoch, from)
        "bar"
      end
      @p.poll do |cs|
        assert_equal("bar", cs)
      end
    end

    def test_poll_should_get_changesets_from_last_change_time_if_known
      ENV["DAMAGECONTROL_HOME"] = RSCM.new_temp_dir("last")

      a = Time.new.utc
      FileUtils.mkdir_p("#{@p.changesets_dir}/#{a.ymdHMS}")
      File.open("#{@p.changesets_dir}/#{a.ymdHMS}/changeset.yaml", "w") do |io|
        cs = RSCM::ChangeSet.new
        cs << RSCM::Change.new("path", "aslak", "hello", "55", Time.new.utc)
        YAML::dump(cs, io)
      end
      @p.scm = new_mock
      changesets = new_mock
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(a+1, from)
        changesets
      end
      @p.scm.__expect(:transactional?) {true}
      @p.poll do |cs|
        assert_equal(changesets, cs)
      end
    end
    
    def test_should_look_at_folders_to_determine_next_changeset_time
      changesets_dir = RSCM.new_temp_dir("folders")
      ENV["DAMAGECONTROL_HOME"] = changesets_dir

      a = Time.new.utc
      b = a + 1
      c = b + 1
      FileUtils.mkdir_p("#{changesets_dir}/#{a.ymdHMS}")
      FileUtils.touch("#{changesets_dir}/#{a.ymdHMS}/changeset.yaml")
      FileUtils.mkdir_p("#{changesets_dir}/#{c.ymdHMS}")
      FileUtils.touch("#{changesets_dir}/#{c.ymdHMS}/changeset.yaml")
      FileUtils.mkdir_p("#{changesets_dir}/#{b.ymdHMS}")
      FileUtils.touch("#{changesets_dir}/#{b.ymdHMS}/changeset.yaml")
      
      assert_equal(c+1, @p.next_changeset_identifier(changesets_dir))
    end

    def test_should_checkout_from_changeset_identifier_and_execute_build
      home = RSCM.new_temp_dir("execute")
      ENV["DAMAGECONTROL_HOME"] = home

      p = Project.new("mooky")
      p.scm = new_mock
      p.scm.__expect(:checkout) do |checkout_dir, changeset_identifier|
        assert_equal("boo", changeset_identifier)
      end

      before = Time.new
      p.build("boo") do |build|
        now = Time.new
        assert(before <= build.time)
        assert(build.time <= now)
        build.execute("some command")

        assert_equal("some command", File.open("#{home}/mooky/changesets/boo/builds/#{build.time.to_s}/command").read)
      end
      
    end
    
    def test_should_load_persisted_builds_that_are_frozen
      p = Project.new("mooky")
      home = RSCM.new_temp_dir("load_builds")
      ENV["DAMAGECONTROL_HOME"] = home

      changeset_identifier = Time.new.utc
      build_1_time = changeset_identifier + 10
      build_2_time = changeset_identifier + 20
      FileUtils.mkdir_p("#{home}/mooky/changesets/#{changeset_identifier.ymdHMS}/builds/#{build_1_time.ymdHMS}")
      FileUtils.touch("#{home}/mooky/changesets/#{changeset_identifier.ymdHMS}/builds/#{build_1_time.ymdHMS}/command")
      FileUtils.mkdir_p("#{home}/mooky/changesets/#{changeset_identifier.ymdHMS}/builds/#{build_2_time.ymdHMS}")

      builds = p.builds(changeset_identifier)
      assert_equal(2, builds.length)
      assert_equal(build_1_time, builds[0].time)
      assert_equal(build_2_time, builds[1].time)
      assert_raises(BuildException, "shouldn't be able to execute persisted build") do
        builds[0].execute("this should fail because command file exists")
      end
      builds[1].execute("this should pass since command doesn't exist")
      assert_raises(BuildException, "shouldn't be able to execute persisted build") do
        builds[1].execute("this should fail because command file exists")
      end
    end
    
    def test_should_convert_to_xml
      p = Project.new
      p.name = "aslak"
      puts p.to_xml
    end
  end
end