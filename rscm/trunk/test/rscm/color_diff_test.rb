require 'test/unit'
require 'rscm/tempdir'
require 'rscm/color_diff'

module RSCM
  class ColorDiffTest < Test::Unit::TestCase
    def test_should_produce_html_for_diff
      cd = ColorDiff.new

      html = RSCM.new_temp_dir + "/sample.html"
      expected_html = File.dirname(__FILE__) + "/simple.html"
      
      File.open(File.dirname(__FILE__) + "/simple.diff") do |diff|
        File.open(html, "w") do |out|
          cd.to_html(diff, out)
        end
      end
      
      assert_equal(File.open(expected_html).read, File.open(html).read)
    end
  end
end