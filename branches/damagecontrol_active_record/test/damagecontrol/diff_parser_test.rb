require 'test/unit'
require 'rscm/tempdir'
require 'rscm/path_converter'
require 'damagecontrol/diff_parser'

# TODO: how do we make this work cross platform in a nicer way?
# Play more with $/, $\ and such
if(WINDOWS)
  NL = "\n"
else
  NL = "\r\n"
end

module DamageControl
  class DiffParserTest < Test::Unit::TestCase
    def test_should_parse_diff_to_object_model
      p = DiffParser.new

      File.open(File.dirname(__FILE__) + "/test.diff") do |diff|
        diffs = p.parse_diffs(diff)
        assert_equal(3, diffs.length)
        assert_equal(7, diffs[1].nplus)
        
        assert_equal(10, diffs[0].line_count)
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

        assert_equal(" package org.picocontainer.sample.tulip;#{NL}", diffs[0][0])
        assert_equal("#{NL}", diffs[0][1])
        #             0         0         0     6   0     6   0
        assert_equal("-import org.picocontainer.lifecycle.Startable;#{NL}", diffs[0][2])
        assert_equal(26..35, diffs[0][2].removed_range)
        assert_equal(nil, diffs[0][2].added_range)
        assert_equal("+import org.picocontainer.Startable;#{NL}", diffs[0][3])
        assert_equal("#{NL}", diffs[0][4])
        assert_equal("-import org.boo.Fillable;#{NL}", diffs[0][5])
        assert_equal(nil, diffs[0][5].removed_range)
        assert_equal(nil, diffs[0][5].added_range)
        assert_equal("+import org.boo.foooooo.Fillable;#{NL}", diffs[0][6])
        assert_equal(nil, diffs[0][6].removed_range)
        assert_equal(16..23, diffs[0][6].added_range)

        assert_equal("- * @version $Revision: 1.1 $#{NL}", diffs[1][3])
        assert_equal(26..26, diffs[1][3].removed_range)
        assert_equal(nil, diffs[1][3].added_range)
        assert_equal("+ * @version $Revision: 1.2 $#{NL}", diffs[1][4])
        assert_equal(nil, diffs[1][4].removed_range)
        assert_equal(26..26, diffs[1][4].added_range)
      end
    end
  end
end