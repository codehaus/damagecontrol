require 'test/unit'
require 'stringio'
require 'damagecontrol/scm/SVNLogParser'

module DamageControl
  class SVNLogParserTest < Test::Unit::TestCase
  
    def setup
      @parser = SVNLogParser.new
    end

SIMPLE_LOG_ENTRY = <<EOF
------------------------------------------------------------------------
r2 | ahelleso | 2004-07-11 14:29:35 +0100 (Sun, 11 Jul 2004) | 1 line
Changed paths:
   M /damagecontrolled/build.xml
   M /damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java

changed something
------------------------------------------------------------------------
EOF
    
    def test_can_parse_SIMPLE_LOG_ENTRY
      changesets = @parser.parse_changesets_from_log(StringIO.new(SIMPLE_LOG_ENTRY))
      assert_equal(1, changesets.length)
      changeset = changesets[0]

      assert_equal("r2", changeset.revision)
      assert_equal("ahelleso", changeset.developer)
      assert_equal(Time.utc(2004,7,11,13,29,35), changeset.time)
      assert_equal("changed something\n", changeset.message)

      assert_equal(2, changeset.length)
      assert_equal("damagecontrolled/build.xml", changeset[0].path)
      assert_equal(Change::MODIFIED, changeset[0].status)
      assert_equal("damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert_equal(Change::MODIFIED, changeset[1].status)
    end
  end
end
