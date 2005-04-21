require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/dependency_graph'

module DamageControl
  class DependencyGraphTest < Test::Unit::TestCase
    include MockIt
    
    def test_should_draw_dependency_graph_with_dot
      dc = new_mock
      rscm = new_mock
      ruby = new_mock
      
      dc.__setup(:name) { "DamageControl" }
      rscm.__setup(:name) { "RSCM" }
      ruby.__setup(:name) { "Ruby" }

      dc.__setup(:dependencies) { [ruby, rscm] }
      rscm.__setup(:dependencies) { [ruby] }
      ruby.__setup(:dependencies) { [] }

      dir = RSCM.new_temp_dir("dependency_graph")
      file = "#{dir}/dependency_graph.png"

      dg = DependencyGraph.new([dc, rscm, ruby])
      dg.write_to(file)
      assert(File.exist?(file))
    end
  end
 end