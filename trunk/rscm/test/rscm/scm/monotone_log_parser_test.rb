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

    def test_should_parse_CHANGESET_to_changeset
      parser = MonotoneLogParser.new
      changeset = parser.parse_changeset(StringIO.new(CHANGESET), {})

      assert_equal("a2c58e276439de7d9da549870e245776c592c7e8", changeset.revision)
      assert_equal("tester@test.net", changeset.developer)
      assert_equal(Time.utc(2005,3,2,6,32,43), changeset.time)

      assert_equal(4, changeset.length)

      assert_equal("build.xml", changeset[0].path)
      assert_equal(Change::ADDED, changeset[0].status)

      assert_equal("project.xml", changeset[1].path)
      assert_equal(Change::ADDED, changeset[1].status)

      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[2].path)
      assert_equal(Change::ADDED, changeset[2].status)

      assert_equal("src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java", changeset[3].path)
      assert_equal(Change::ADDED, changeset[3].status)

      assert_equal("imported\nsources", changeset.message)
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

    def test_should_parse_CHANGESETS_to_changesets
      parser = MonotoneLogParser.new
      changesets = parser.parse_changesets(StringIO.new(CHANGESETS))
      assert_equal(2, changesets.length)
      changeset = changesets[0]

      assert_equal("build.xml", changeset[0].path)
      assert_equal(Change::MODIFIED, changeset[0].status)

      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert_equal(Change::MODIFIED, changeset[1].status)
    end

    def test_should_parse_CHANGESETS_to_changesets_before
      parser = MonotoneLogParser.new
      changesets = parser.parse_changesets(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,32,42))
      assert_equal(2, changesets.length)

      changesets = parser.parse_changesets(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,32,43))
      assert_equal(1, changesets.length)

      changesets = parser.parse_changesets(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,33,00))
      assert_equal(1, changesets.length)

      changesets = parser.parse_changesets(StringIO.new(CHANGESETS), Time.utc(2005,03,02,06,33,01))
      assert_equal(0, changesets.length)
    end

    def test_should_parse_CHANGESETS_to_changesets_before_with_ids
      parser = MonotoneLogParser.new
      changesets = parser.parse_changesets(StringIO.new(CHANGESETS), "a2c58e276439de7d9da549870e245776c592c7e8")
      assert_equal(1, changesets.length)
      assert_equal("a2c58e276439de7d9da549870e245776c592c7e8", changesets[0][0].previous_revision)
      assert_equal("abbe1eb8f75bdf9b27d440340ec329816c13985c", changesets[0][0].revision)


      changesets = parser.parse_changesets(StringIO.new(CHANGESETS), "abbe1eb8f75bdf9b27d440340ec329816c13985c")
      assert_equal(0, changesets.length)
    end

    def test_should_parse_CHANGESET_to_changesets
      parser = MonotoneLogParser.new
      changesets = parser.parse_changesets(StringIO.new(CHANGESET))
      assert_equal(1, changesets.length)
    end

  end
end
