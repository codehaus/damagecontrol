require 'test/unit'
require 'tempdir'
require 'rscm/mockit'
require 'rscm'

RSS_SERVICE = nil

module RSCM
  class ProjectTest < Test::Unit::TestCase
    include MockIt
    
    def test_poll_should_get_changesets_from_epoch_if_last_change_time_unknown
      p = Project.new
      p.name = "A"
      p.scm = new_mock
      p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(Time.epoch, from)
        changesets = new_mock
        changesets.__expect(:empty?){false}
        changesets.__expect(:save)
      end
      p.poll
    end

    def test_poll_should_get_changesets_from_last_change_time_if_known
      p = Project.new
      p.name = "B"

      a = Time.new.utc
      FileUtils.mkdir_p("#{p.changesets_dir}/#{a.ymdHMS}")
      p.scm = new_mock
      p.scm.__expect(:changesets) do |checkout_dir, from|
        assert_equal(a+1, from)
        changesets = new_mock
        changesets.__expect(:empty?){false}
        changesets.__expect(:save)
      end
      p.poll
    end
    
    def test_should_look_at_folders_to_determine_next_changeset_time
      changes_dir = RSCM.new_temp_dir
      a = Time.new.utc
      b = a + 1
      c = b + 1
      FileUtils.mkdir_p("#{changes_dir}/#{a.ymdHMS}")
      FileUtils.mkdir_p("#{changes_dir}/#{c.ymdHMS}")
      FileUtils.mkdir_p("#{changes_dir}/#{b.ymdHMS}")
      
      p = Project.new
      assert_equal(c+1, p.next_changeset_time(changes_dir))
    end
  end
end