require 'test/unit'
require 'rscm/mockit'
require 'damagecontrol/project'
require 'damagecontrol/poller'

module DamageControl
  class PollerTest < Test::Unit::TestCase
    include MockIt
  
    def test_should_not_add_projects_twice
      s = Poller.new
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

    def test_yields_project_and_changesets_for_each_project_with_changesets
      p1 = Project.new; p1.name = "p2"
      p1.scm = new_mock
      p1.scm.__expect(:exists?) {true}
      p1.scm.__expect(:changesets) {"some fake changesets"}
      p1.scm.__expect(:transactional?) {true}

      p2 = Project.new; p2.name = "p1"
      p2.scm = new_mock
      p2.scm.__expect(:exists?) {true}
      p2.scm.__expect(:changesets) {"some other fake changesets"}
      p2.scm.__expect(:transactional?) {true}

      projects = []
      changesets_ = []
      s = Poller.new do |project, changesets|
        projects << project
        changesets_ << changesets
      end
      s.add_project(p1)
      s.add_project(p2)

      s.poll
      
      assert_same(p1, projects[0])
      assert_same(p2, projects[1])
      assert_equal("some fake changesets", changesets_[0])
      assert_equal("some other fake changesets", changesets_[1])
    end
    
  end
end