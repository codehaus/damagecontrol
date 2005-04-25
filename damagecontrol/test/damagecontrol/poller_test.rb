require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/project'
require 'damagecontrol/poller'

module DamageControl
  class PollerTest < Test::Unit::TestCase
    include MockIt
  
    def test_yields_project_and_revisions_for_each_project_with_revisions
      tmp = RSCM.new_temp_dir("DiffPersisterTest")

      revisions1 = RSCM::Revisions.new
      revisions1.add(RSCM::Revision.new)
      
      p1 = Project.new("foo")
      p1.dir = "#{tmp}/foo"
      p1.scm = new_mock
      p1.scm.__expect(:central_exists?) {true}
      p1.scm.__expect(:revisions) {revisions1}
      p1.scm.__expect(:transactional?) {true}
      p1.scm.__setup(:name) {"MockSCM1"}

      projects_ = []
      revisions_ = []
      s = Poller.new(nil) do |project, revisions|
        projects_ << project
        revisions_ << revisions
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
      assert_equal(revisions1, revisions_[0])
    end
  end
end