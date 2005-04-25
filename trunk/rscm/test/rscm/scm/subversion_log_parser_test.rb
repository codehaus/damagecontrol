require 'test/unit'
require 'stringio'
require 'rscm'

module RSCM
  class SubversionLogParserTest < Test::Unit::TestCase

SIMPLE_LOG_ENTRY = <<EOF
r2 | ahelleso | 2004-07-11 14:29:35 +0100 (Sun, 11 Jul 2004) | 1 line
Changed paths:
   M /damagecontrolled/build.xml
   M /damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java

changed something
else
------------------------------------------------------------------------
EOF

SIMPLE_LOG_ENTRY_WITH_BACKSLASHES = <<EOF
r2 | ahelleso | 2004-07-11 14:29:35 +0100 (Sun, 11 Jul 2004) | 1 line
Changed paths:
   M \\damagecontrolled\\build.xml
   M \\damagecontrolled\\src\\java\\com\\thoughtworks\\damagecontrolled\\Thingy.java

changed something
else
------------------------------------------------------------------------
EOF
    
    def test_can_parse_SIMPLE_LOG_ENTRIES
      parser = SubversionLogEntryParser.new("damagecontrolled", "damagecontrolled")
      can_parse_simple_log_entry(parser, SIMPLE_LOG_ENTRY)
      can_parse_simple_log_entry(parser, SIMPLE_LOG_ENTRY_WITH_BACKSLASHES)
    end
    
    def can_parse_simple_log_entry(parser, entry)
      revision = parser.parse(StringIO.new(entry)) {|line|}

      assert_equal(2, revision.identifier)
      assert_equal("ahelleso", revision.developer)
      assert_equal(Time.utc(2004,7,11,13,29,35), revision.time)
      assert_equal("changed something\nelse", revision.message)

      assert_equal(2, revision.length)
      assert_equal("build.xml", revision[0].path)
      assert_equal(2, revision[0].native_revision_identifier)
      assert_equal(RevisionFile::MODIFIED, revision[0].status)
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", revision[1].path)
      assert_equal(RevisionFile::MODIFIED, revision[1].status)
    end

    def test_parses_entire_log_into_revisions
      File.open(File.dirname(__FILE__) + "/svn-proxytoys.log") do |io|
        parser = SubversionLogParser.new(io, "trunk/proxytoys", nil)

        revisions = parser.parse_revisions
        
        assert_equal(66, revisions.length)
        # just some random assertions
        assert_equal(
          "DecoratingInvoker now hands off to a SimpleInvoker rather than a DelegatingInvoker if constructed with an Object to decorate.\n" +
          "Added protected getDelegateMethod(name, params)\n", revisions[0].message)

        assert_equal(66, revisions[3].revision)
        assert_equal("tastapod", revisions[3].developer)
        assert_equal(Time.utc(2004,05,24,17,06,18,0), revisions[3].time)
        assert_match(/Factored delegating behaviour out/ , revisions[3].message)
        assert_equal(15, revisions[3].length)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/DelegatingInvoker.java" , revisions[3][1].path)
        assert_equal(RevisionFile::ADDED , revisions[3][1].status)
        assert_equal(66 , revisions[3][1].revision)
        assert_equal(65, revisions[3][1].previous_native_revision_identifier)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/ObjectReference.java" , revisions[3][3].path)
        assert_equal(RevisionFile::MOVED, revisions[3][3].status)

        assert_equal("src/com/thoughtworks/proxy/toys/delegate/OldDelegatingInvoker.java" , revisions[3][4].path)
        assert_equal(RevisionFile::DELETED, revisions[3][4].status)

        assert_equal("test/com/thoughtworks/proxy/toys/echo/EchoingTest.java" , revisions[3][14].path)
        assert_equal(RevisionFile::MODIFIED , revisions[3][14].status)

      end
    end

    def test_parses_entire_log_into_revisions
      File.open(File.dirname(__FILE__) + "/svn-cargo.log") do |io|
        parser = SubversionLogParser.new(io, "trunk/proxytoys", nil)
        revisions = parser.parse_revisions
        assert_equal(16, revisions.length)
      end
    end

    def test_parses_another_tricky_log
      File.open(File.dirname(__FILE__) + "/svn-growl.log") do |io|
        parser = SubversionLogParser.new(io, "trunk", nil)
        revisions = parser.parse_revisions
        assert_equal(82, revisions.length)
      end
    end

    def test_parses_log_with_spaces_in_file_names
      File.open(File.dirname(__FILE__) + "/svn-growl2.log") do |io|
        parser = SubversionLogParser.new(io, "trunk", nil)
        revisions = parser.parse_revisions
        change = revisions[1][0]
        assert_equal("Display Plugins/Bezel/English.lproj/GrowlBezelPrefs.nib/classes.nib", change.path)
      end
    end

SVN_R_LOG_HEAD_DATA = <<-EOF
------------------------------------------------------------------------
r48 | rinkrank | 2004-10-16 20:07:29 -0500 (Sat, 16 Oct 2004) | 1 line

nothing
------------------------------------------------------------------------
EOF

    def test_should_retrieve_head_revision
      parser = SubversionLogParser.new(StringIO.new(SVN_R_LOG_HEAD_DATA), "blah", nil)
      revisions = parser.parse_revisions
      assert_equal(48, revisions[0].identifier)
    end
  end
end
