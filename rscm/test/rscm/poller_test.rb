require 'test/unit'
require 'rscm/mockit'
require 'rscm'

module RSCM
  class PollerTest < Test::Unit::TestCase
    include MockIt
  
    def test_should_not_add_projects_twice
      s = Poller.new(0)
      a1 = Project.new; a1.name = "jalla"
      s.add_project(a1)
      assert_equal([a1], s.projects)

      a2 = Project.new; a2.name = "jalla"
      s.add_project(a2)
      assert_equal([a2], s.projects)

      b = Project.new; b.name = "mooky"
      s.add_project(b)
      assert_equal([a2, b], s.projects)
    end

    def test_should_tell_all_projects_to_poll
      p = new_mock
      p.__expect(:scm_exists?){true}
      p.__expect(:poll)

      s = Poller.new(0)
      s.add_project(p)
      s.poll
    end
    
    def test_should_poll_in_a_loop
      p = new_mock
      p.__expect(:scm_exists?){false}
      p.__expect(:scm_exists?){true}
      p.__expect(:poll)

      s = Poller.new(2)
      s.add_project(p)
      s.start
      sleep 3
      s.stop
    end
  end
end