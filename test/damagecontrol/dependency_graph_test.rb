require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'rscm/difftool_test'
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

      dc.__setup(:depends_on?) {|p| p == ruby || p == rscm }
      rscm.__setup(:depends_on?) {|p| p == ruby }
      ruby.__setup(:depends_on?) {|p| false }

      dc.__setup(:dependencies) { [ruby, rscm] }
      rscm.__setup(:dependencies) { [ruby] }
      ruby.__setup(:dependencies) { [] }

      dir = RSCM.new_temp_dir("dependency_graph")
      dg = DependencyGraph.new(rscm, [dc, rscm, ruby], String)

      png_file = "#{dir}/dependency_graph.png"
      dot_file = "#{dir}/dependency_graph.dot"
      html_file = "#{dir}/dependency_graph.html"

      dg.write_to(png_file)

      expected_dot = File.dirname(__FILE__) + "/expected_dependency_graph.dot"
      assert_equal_with_diff(File.open(expected_dot).read, File.open(dot_file).read)

      expected_html = File.dirname(__FILE__) + "/expected_dependency_graph.html"
      assert_equal_with_diff(File.open(expected_html).read, File.open(html_file).read)

      assert(File.exist?(png_file))
    end
  end
 end