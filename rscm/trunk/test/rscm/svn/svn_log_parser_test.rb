require 'test/unit'
require 'stringio'
require 'rscm/svn/svn_log_parser'

module RSCM
  class SVNLogParserTest < Test::Unit::TestCase
  
#    include FileUtils

SIMPLE_LOG_ENTRY = <<EOF
r2 | ahelleso | 2004-07-11 14:29:35 +0100 (Sun, 11 Jul 2004) | 1 line
Changed paths:
   M /damagecontrolled/build.xml
   M /damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java

changed something
------------------------------------------------------------------------
EOF

SIMPLE_LOG_ENTRY_WITH_BACKSLASHES = <<EOF
r2 | ahelleso | 2004-07-11 14:29:35 +0100 (Sun, 11 Jul 2004) | 1 line
Changed paths:
   M \\damagecontrolled\\build.xml
   M \\damagecontrolled\\src\\java\\com\\thoughtworks\\damagecontrolled\\Thingy.java

changed something
------------------------------------------------------------------------
EOF
    
    def test_can_parse_SIMPLE_LOG_ENTRIES
      parser = SVNLogEntryParser.new("damagecontrolled", "damagecontrolled")
      can_parse_simple_log_entry(parser, SIMPLE_LOG_ENTRY)
      can_parse_simple_log_entry(parser, SIMPLE_LOG_ENTRY_WITH_BACKSLASHES)
    end
    
    def can_parse_simple_log_entry(parser, entry)
      changeset = parser.parse(StringIO.new(entry)) {|line|}

      assert_equal("2", changeset.revision)
      assert_equal("ahelleso", changeset.developer)
      assert_equal(Time.utc(2004,7,11,13,29,35), changeset.time)
      assert_equal("changed something", changeset.message)

      assert_equal(2, changeset.length)
      assert_equal("build.xml", changeset[0].path)
      assert_equal("2", changeset[0].revision)
      assert_equal(Change::MODIFIED, changeset[0].status)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert_equal(Change::MODIFIED, changeset[1].status)
    end

    def test_parses_entire_log_into_changesets
      File.open("#{damagecontrol_home}/testdata/proxytoys-svn.log") do |io|
        parser = SVNLogParser.new(io, "trunk/proxytoys", nil)

        start_date = Time.utc(2004,02,13,19,02,44,0)
        end_date = Time.utc(2004,9,06,14,50,25,0)

        changesets = parser.parse_changesets(start_date, end_date) {|line|}
        
        assert_equal(66, changesets.length)
        # just some random assertions
        assert_equal(
          "DecoratingInvoker now hands off to a SimpleInvoker rather than a DelegatingInvoker if constructed with an Object to decorate.\n" +
          "Added protected getDelegateMethod(name, params)\n", changesets[0].message)

        assert_equal("66", changesets[3].revision)
        assert_equal("tastapod", changesets[3].developer)
        assert_equal(Time.utc(2004,05,24,17,06,18,0), changesets[3].time)
        assert_match(/Factored delegating behaviour out/ , changesets[3].message)
        assert_equal(15, changesets[3].length)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/DelegatingInvoker.java" , changesets[3][1].path)
        assert_equal(Change::ADDED , changesets[3][1].status)
        assert_equal("66" , changesets[3][1].revision)
        assert_equal("65", changesets[3][1].previous_revision)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/ObjectReference.java" , changesets[3][3].path)
        assert_equal(Change::MOVED, changesets[3][3].status)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/OldDelegatingInvoker.java" , changesets[3][4].path)
        assert_equal(Change::DELETED, changesets[3][4].status)

        assert_equal("test/com/thoughtworks/proxy/toys/echo/EchoingTest.java" , changesets[3][14].path)
        assert_equal(Change::MODIFIED , changesets[3][14].status)

      end
    end

    def test_parses_entire_log_into_changesets
      File.open(File.dirname(__FILE__) + "/cargo-svn.log") do |io|
        parser = SVNLogParser.new(io, "trunk/proxytoys", nil)
        changesets = parser.parse_changesets(nil, nil)
        assert_equal(16, changesets.length)
      end
    end
    
    def test_skips_entries_outside_range
      File.open(File.dirname(__FILE__) + "/proxytoys-svn.log") do |io|
        parser = SVNLogParser.new(io, "trunk/proxytoys", nil)
        # revisions r16, r17 and r18
        start_date = Time.utc(2004,04,14,14,17,35,0) # same as r15
        end_date = Time.utc(2004,05,10,22,36,25,0) # same as r18
        changesets = parser.parse_changesets(start_date, end_date) {|line|}
        assert_equal(3, changesets.length)

        assert_equal("18", changesets[0].revision)
        assert_equal("17", changesets[1].revision)
        assert_equal("16", changesets[2].revision)
      end
    end

SVN_R_LOG_HEAD_DATA = <<-EOF
------------------------------------------------------------------------
r48 | rinkrank | 2004-10-16 20:07:29 -0500 (Sat, 16 Oct 2004) | 1 line

nothing
------------------------------------------------------------------------
EOF

    def test_should_retrieve_head_revision
      parser = SVNLogParser.new(StringIO.new(SVN_R_LOG_HEAD_DATA), "blah", nil)
      changesets = parser.parse_changesets
      assert_equal("48", changesets[0].revision)
    end
  end
end
