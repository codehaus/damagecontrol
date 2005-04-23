require 'test/unit'
require 'yaml'
require 'rscm'
require 'rscm/tempdir'
require 'rscm/mockit'
require 'rscm/changes'
require 'damagecontrol/project'
require 'damagecontrol/json_ext'

module DamageControl
  class ProjectTest < Test::Unit::TestCase
    include MockIt
    
    def setup
      MockIt::setup
      @p = Project.new
      @p.name = "blabla"
    end
    
    def test_poll_should_get_changesets_from_start_time_if_last_change_time_unknown
      dir = RSCM.new_temp_dir("ProjectTest1")

      @p.dir = dir
      @p.scm = new_mock
      @p.scm.__setup(:name) {"MockSCM"}
      changesets = new_mock
      changesets.__setup(:empty?) {true}
      changesets.__expect(:each) {Proc.new{|changeset|}}
      @p.scm.__expect(:changesets) do |from|
        assert_equal(@p.start_time, from)
        changesets
      end
      @p.poll do |cs|
        assert_equal(changesets, cs)
      end
    end

    def test_poll_should_poll_until_quiet_period_elapsed
      dir = RSCM.new_temp_dir("ProjectTest2")
      @p.dir = dir
      @p.quiet_period = 0
      @p.scm = new_mock
      @p.scm.__setup(:name) {"mooky"}
      @p.scm.__expect(:changesets) do |from|
        assert_equal(@p.start_time, from)
        cs = RSCM::ChangeSets.new
        cs.add(RSCM::ChangeSet.new)
        cs
      end
      @p.scm.__expect(:transactional?) {false}
      @p.scm.__expect(:changesets) do |from|
        assert_equal(@p.start_time, from)
        RSCM::ChangeSets.new
      end
      @p.scm.__expect(:changesets) do |from|
        assert_equal(@p.start_time, from)
        RSCM::ChangeSets.new
      end
      @p.poll do |cs|
        assert_equal(RSCM::ChangeSets, cs.class)
      end
    end

    def test_poll_should_get_changesets_from_last_change_time_if_known
      dir = RSCM.new_temp_dir("ProjectTest3")
      @p.dir = dir

      a = Time.new.utc
      FileUtils.mkdir_p("#{@p.changesets_dir}/#{a.ymdHMS}")
      File.open("#{@p.changesets_dir}/#{a.ymdHMS}/changeset.yaml", "w") do |io|
        cs = RSCM::ChangeSet.new
        cs << RSCM::Change.new("path", "aslak", "hello", "55", Time.new.utc)
        YAML::dump(cs, io)
      end
      @p.scm = new_mock
      @p.scm.__setup(:name) {"MockSCM"}
      changesets = new_mock
      changesets.__setup(:empty?) {false}
      changesets.__expect(:each) {Proc.new{|changeset|}}
      @p.scm.__expect(:changesets) do |from|
        assert_equal(a, from)
        changesets
      end
      @p.scm.__expect(:transactional?) {true}
      @p.poll do |cs|
        assert_equal(changesets, cs)
      end
    end
    
    def test_should_tell_each_publisher_to_publish_build
      p = Project.new("mooky")
      p.publishers = []
      
      build = new_mock

      enabled_publisher = new_mock
      enabled_publisher.__setup(:name) {"I am enabled"}
      enabled_publisher.__expect(:enabled) {true}
      enabled_publisher.__expect(:publish) do |b|
        assert_equal(build, b)
      end
      p.publishers << enabled_publisher
      
      disabled_publisher = new_mock
      disabled_publisher.__setup(:name) {"I am disabled"}
      disabled_publisher.__expect(:enabled) {false}
      p.publishers << disabled_publisher

      p.publish(build)
    end
    
    def test_should_convert_start_time_string_to_time
      p = Project.new
      p.start_time = "19710228234533"
      assert_equal(Time.utc(1971,2,28,23,45,33), p.start_time)
    end

    def test_should_support_template_cloning
      # Create a template object
      template_project = Project.new
      template_project.home_page = "http://\#{unix_name}.codehaus.org"

      # Create a duplicate from the template object
      dupe = template_project.dupe("unix_name" => "mooky")      
      assert_equal("http://mooky.codehaus.org", dupe.home_page);
    end

    def test_should_store_dependencies
      dir = RSCM.new_temp_dir("deps")

      a = Project.new("a")
      a.dir = "#{dir}/a"
      b = Project.new("b")
      b.dir = "#{dir}/b"

      a.add_dependency(b)
      b.save
      a.save
      
      a2 = Project.load("#{a.dir}/project.yaml")
      assert_equal([b], a2.dependencies)
    end

    def test_should_detect_transitive_dependencies
      $a = Project.new("a")
      $b = Project.new("b")
      $c = Project.new("c")
      
      def $a.dependencies
        [$b]
      end

      def $b.dependencies
        [$c]
      end
      
      assert($a.depends_on?($c))
    end

    def test_should_not_allow_cyclical_dependencies
      $a = Project.new("a")
      $b = Project.new("b")
      $c = Project.new("c")
      
      def $a.dependencies
        [$b]
      end

      def $b.dependencies
        [$c]
      end

      assert_raise(RuntimeError) do
        $c.add_dependency($a)
      end
    end
    
  end
end