require 'test/unit'
require 'stringio'
require 'rscm'

module RSCM
  class MonotoneLogParserTest < Test::Unit::TestCase
  
CHANGESET = <<EOF
-----------------------------------------------------------------
Revision: a2c58e276439de7d9da549870e245776c592c7e8
Author: tester@test.net
Date: 2005-03-02T06:32:43

Added files:
        build.xml project.xml
        src/java/com/thoughtworks/damagecontrolled/Thingy.java
        src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java

ChangeLog:

imported
sources
EOF

    def test_should_parse_CHANGESET_to_revision
      parser = MonotoneLogParser.new
      revision = parser.parse_revision(StringIO.new(CHANGESET), {})

      assert_equal("a2c58e276439de7d9da549870e245776c592c7e8", revision.identifier)
      assert_equal("tester@test.net", revision.developer)
      assert_equal(Time.utc(2005,3,2,6,32,43), revision.time)

      assert_equal(4, revision.length)

      assert_equal("build.xml", revision[0].path)
      assert_equal(RevisionFile::ADDED, revision[0].status)

      assert_equal("project.xml", revision[1].path)
      assert_equal(RevisionFile::ADDED, revision[1].status)

      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", revision[2].path)
      assert_equal(RevisionFile::ADDED, revision[2].status)

      assert_equal("src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java", revision[3].path)
      assert_equal(RevisionFile::ADDED, revision[3].status)

      assert_equal("imported\nsources", revision.message)
    end

CHANGESETS = <<EOF
-----------------------------------------------------------------
Revision: abbe1eb8f75bdf9b27d440340ec329816c13985c
Author: tester@test.net
Date: 2005-03-02T06:33:01

Modified files:
        build.xml
        src/java/com/thoughtworks/damagecontrolled/Thingy.java

ChangeLog:

changed
something
-----------------------------------------------------------------
Revision: a2c58e276439de7d9da549870e245776c592c7e8
Author: tester@test.net
Date: 2005-03-02T06:32:43

Added files:
        build.xml project.xml
        src/java/com/thoughtworks/damagecontrolled/Thingy.java
        src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java

ChangeLog:

imported
sources
EOF

    def test_should_parse_CHANGESETS_to_revisions
      parser = MonotoneLogParser.new
      revisions = parser.parse_revisions(StringIO.new(CHANGESETS))
      assert_equal(2, revisions.length)
      revision = revisions[0]

      assert_equal("build.xml", revision[0].path)
      assert_equal(RevisionFile::MODIFIED, revision[0].status)

      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", revision[1].path)
      assert_equal(RevisionFile::MODIFIED, revision[1].status)
    end

    def test_should_parse_CHANGESETS_to_revisions_before
      parser = MonotoneLogParser.new
      revisions = parser.parse_revisions(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,32,42))
      assert_equal(2, revisions.length)

      revisions = parser.parse_revisions(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,32,43))
      assert_equal(1, revisions.length)

      revisions = parser.parse_revisions(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,33,00))
      assert_equal(1, revisions.length)

      revisions = parser.parse_revisions(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,33,01))
      assert_equal(0, revisions.length)
    end

    def test_should_parse_CHANGESETS_to_revisions_before_with_ids
      parser = MonotoneLogParser.new
      revisions = parser.parse_revisions(StringIO.new(CHANGESETS), "a2c58e276439de7d9da549870e245776c592c7e8")
      assert_equal(1, revisions.length)
      assert_equal("a2c58e276439de7d9da549870e245776c592c7e8", revisions[0][0].previous_native_revision_identifier)
      assert_equal("abbe1eb8f75bdf9b27d440340ec329816c13985c", revisions[0][0].revision)


      revisions = parser.parse_revisions(StringIO.new(CHANGESETS), "abbe1eb8f75bdf9b27d440340ec329816c13985c")
      assert_equal(0, revisions.length)
    end

    def test_should_parse_CHANGESET_to_revisions
      parser = MonotoneLogParser.new
      revisions = parser.parse_revisions(StringIO.new(CHANGESET))
      assert_equal(1, revisions.length)
    end

  end
end
