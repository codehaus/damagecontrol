require 'test/unit'
require 'rscm/tempdir'
require 'rscm/color_diff'

module RSCM
  class DiffParserTest < Test::Unit::TestCase
    def test_should_parse_diff_to_object_model
      p = DiffParser.new

      File.open(File.dirname(__FILE__) + "/simple.diff") do |diff|
        diffs = p.parse_diffs(diff)
        assert_equal(3, diffs.length)
        assert_equal(7, diffs[1].nplus)
        
        assert_equal(7, diffs[0].line_count)
        assert_equal(8, diffs[1].line_count)
        assert_equal(9, diffs[2].line_count)
        
        assert(!diffs[0][0].removed?)
        assert(!diffs[0][0].added?)
        assert(!diffs[0][1].removed?)
        assert(!diffs[0][1].added?)
        assert( diffs[0][2].removed?)
        assert(!diffs[0][2].added?)
        assert(!diffs[0][3].removed?)
        assert( diffs[0][3].added?)

        assert_equal("package org.picocontainer.sample.tulip;\n", diffs[0][0].content)
        assert_equal("\n", diffs[0][1].content)
        
        assert_equal(25..34, diffs[0][1].removed_range)
      end
    end
  end
end