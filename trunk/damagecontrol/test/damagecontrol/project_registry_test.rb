require 'test/unit'
require 'damagecontrol/project'
require 'damagecontrol/project_registry'

module DamageControl
  class ProjectTest < Test::Unit::TestCase
    include RSCM
  
    def test_should_list_all_candidate_project_dependencies
      pr = ProjectRegistry.new
      a = Project.new("a")
      b = Project.new("b")
      c = Project.new("c")
      
      pr.add(a)
      pr.add(b)
      pr.add(c)
      
      assert_equal([b,c], pr.candidate_dependencies(a))
    end
  
  end
end