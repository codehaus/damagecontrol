require 'test/unit'
require 'stringio'
require 'damagecontrol/scm/SVNLogParser'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class SVNLogParserTest < Test::Unit::TestCase
  
    include FileUtils

    def test_read_log_entry_reads_till_line_of_underscores
      assert_equal("blahblah\n", SVNLogParser.new(StringIO.new("blahblah\n---------------\nubbaubba\n---------------"), "").next_log_entry)
      assert_equal("ubbaubba\n", SVNLogParser.new(StringIO.new("---------------\nubbaubba\n---------------"), "").next_log_entry)
      assert_equal(nil, SVNLogParser.new(StringIO.new(""), "").next_log_entry)
      assert_equal(nil, SVNLogParser.new(StringIO.new("------\n---------------"), "").next_log_entry)
    end
    
    def test_can_parse_changeset
      parser = SVNLogParser.new(nil, "damagecontrolled")
      changeset = parser.parse_changeset(SIMPLE_LOG_ENTRY.split("\n")[1..-2].join("\n"))
      assert_equal("r2", changeset.revision)
      assert_equal("ahelleso", changeset.developer)
      assert_equal(Time.utc(2004,7,11,13,29,35), changeset.time)
      assert_equal("changed something\n", changeset.message)
      
      assert_equal(2, changeset.length)
      assert_equal("build.xml", changeset[0].path)
      assert_equal("r2", changeset[0].revision)
      assert_equal("r1", changeset[0].previous_revision)
      assert_equal(Change::MODIFIED, changeset[0].status)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert_equal(Change::MODIFIED, changeset[1].status)
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

SIMPLE_LOG_ENTRY_WITH_BACKSLASHES = <<EOF
------------------------------------------------------------------------
r2 | ahelleso | 2004-07-11 14:29:35 +0100 (Sun, 11 Jul 2004) | 1 line
Changed paths:
   M \damagecontrolled\build.xml
   M \damagecontrolled\src\java\com\thoughtworks\damagecontrolled\Thingy.java

changed something
------------------------------------------------------------------------
EOF
    
    def test_can_parse_SIMPLE_LOG_ENTRY
      can_parse_simple_log_entry(SIMPLE_LOG_ENTRY)
    end
    
    def Xtest_can_parse_SIMPLE_LOG_ENTRY_WITH_BACKSLASHES
      can_parse_simple_log_entry(SIMPLE_LOG_ENTRY_WITH_BACKSLASHES)
    end
    
    def can_parse_simple_log_entry(entry)
      parser = SVNLogParser.new(StringIO.new(entry), "damagecontrolled")
      changesets = parser.parse_changesets
      assert_equal(1, changesets.length)
      changeset = changesets[0]

      assert_equal("r2", changeset.revision)
      assert_equal("ahelleso", changeset.developer)
      assert_equal(Time.utc(2004,7,11,13,29,35), changeset.time)
      assert_equal("changed something\n", changeset.message)

      assert_equal(2, changeset.length)
      assert_equal("build.xml", changeset[0].path)
      assert_equal("r2", changeset[0].revision)
      assert_equal("r1", changeset[0].previous_revision)
      assert_equal(Change::MODIFIED, changeset[0].status)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert_equal(Change::MODIFIED, changeset[1].status)
    end

    def test_parses_entire_log_into_changesets
      File.open("#{damagecontrol_home}/testdata/proxytoys-svn.log") do |io|
        parser = SVNLogParser.new(io, "trunk/proxytoys")
        changesets = parser.parse_changesets
        
        assert_equal(66, changesets.length)
        # just some random assertions
        assert_equal(
          "DecoratingInvoker now hands off to a SimpleInvoker rather than a DelegatingInvoker if constructed with an Object to decorate.\n" +
          "Added protected getDelegateMethod(name, params)\n", changesets[0].message)

        assert_equal("r66", changesets[3].revision)
        assert_equal("tastapod", changesets[3].developer)
        assert_equal(Time.utc(2004,05,24,17,06,18,0), changesets[3].time)
        assert_match(/Factored delegating behaviour out/ , changesets[3].message)
        assert_equal(15, changesets[3].length)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/DelegatingInvoker.java" , changesets[3][1].path)
        assert_equal(Change::ADDED , changesets[3][1].status)
        assert_equal("r66" , changesets[3][1].revision)
        assert_equal("r65", changesets[3][1].previous_revision)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/ObjectReference.java" , changesets[3][3].path)
        assert_equal(Change::MOVED, changesets[3][3].status)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/OldDelegatingInvoker.java" , changesets[3][4].path)
        assert_equal(Change::DELETED, changesets[3][4].status)

        assert_equal("test/com/thoughtworks/proxy/toys/echo/EchoingTest.java" , changesets[3][14].path)
        assert_equal(Change::MODIFIED , changesets[3][14].status)

      end
    end
    
  end
end
