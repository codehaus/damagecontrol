require 'test/unit'
require 'rscm/tempdir'
require 'rscm/mockit'
require 'rscm'

RSS_SERVICE = nil

module RSCM
  class ProjectTest < Test::Unit::TestCase
    include MockIt
    
    def setup
      MockIt::setup
      @p = Project.new
      @p.description = "bla bla"
      @p.name = "blabla"
    end
    
    def test_poll_should_get_changesets_from_epoch_if_last_change_time_unknown
      ENV["RSCM_BASE"] = RSCM.new_temp_dir + "/epoch"

      @p.scm = new_mock
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(Time.epoch, from)
        changesets = new_mock
        changesets.__expect(:empty?){false}
        changesets.__expect(:accept)
        changesets.__expect(:accept)
      end
      @p.poll
    end

    def Xtest_poll_should_get_changesets_from_last_change_time_if_known
      ENV["RSCM_BASE"] = RSCM.new_temp_dir + "/last"

      a = Time.new.utc
      FileUtils.mkdir_p("#{@p.changesets_dir}/#{a.ymdHMS}")
      File.open("#{@p.changesets_dir}/#{a.ymdHMS}/changeset.yaml", "w") do |io|
        cs = ChangeSet.new
        cs << Change.new("path", "aslak", "hello", "55", Time.new.utc)
        YAML::dump(cs, io)
      end
      @p.scm = new_mock
      @p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(a+1, from)
        changesets = new_mock
        changesets.__expect(:empty?){false}
        changesets.__expect(:accept)
        changesets.__expect(:accept)
      end
      @p.poll
    end
    
    def Xtest_should_look_at_folders_to_determine_next_changeset_time
      changesets_dir = RSCM.new_temp_dir
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
  end
end