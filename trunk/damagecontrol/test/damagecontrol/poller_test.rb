require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/project'
require 'damagecontrol/poller'

module DamageControl
  class PollerTest < Test::Unit::TestCase
    include MockIt
  
    def test_yields_project_and_changesets_for_each_project_with_changesets
      tmp = RSCM.new_temp_dir("DiffPersisterTest")

      changesets1 = RSCM::ChangeSets.new
      changesets1.add(RSCM::ChangeSet.new)
      
      p1 = Project.new("foo")
      p1.dir = "#{tmp}/foo"
      p1.scm = new_mock
      p1.scm.__expect(:exists?) {true}
      p1.scm.__expect(:changesets) {changesets1}
      p1.scm.__expect(:transactional?) {true}
      p1.scm.__setup(:name) {"MockSCM1"}

      projects_ = []
      changesets_ = []
      s = Poller.new(nil) do |project, changesets|
        projects_ << project
        changesets_ << changesets
      end

      def Project.projects=(p)
        @projects = p
      end

      def Project.find_all(projects_dir_ignore)
        @projects
      end
      
      Project.projects = [p1]

      s.poll
      
      assert_same(p1, projects_[0])
      assert_equal(changesets1, changesets_[0])
    end
  end
end