require 'test/unit'
require 'stringio'
require 'rscm'

module RSCM
  class DarcsLogParserTest < Test::Unit::TestCase

CHANGESET = <<EOF
<patch author='tester@test.net' date='20050327203534' local_date='Sun Mar 27 16:35:34 AST 2005' inverted='False' hash='20050327203534-4d520-baeeafb062e7f0d72ce740e1e1f5e6a203321ab4.gz'>
        <name>something nice</name>
        <comment>
        imported
sources
        </comment>
    <summary>
    <add_file>
    build.xml
    </add_file>
    <add_file>
    project.xml
    </add_file>
    <add_directory>
    src
    </add_directory>
    <add_directory>
    src/java
    </add_directory>
    <add_directory>
    src/java/com
    </add_directory>
    <add_directory>
    src/java/com/thoughtworks
    </add_directory>
    <add_directory>
    src/java/com/thoughtworks/damagecontrolled
    </add_directory>
    <add_file>
    src/java/com/thoughtworks/damagecontrolled/Thingy.java
    </add_file>
    <add_directory>
    src/test
    </add_directory>
    <add_directory>
    src/test/com
    </add_directory>
    <add_directory>
    src/test/com/thoughtworks
    </add_directory>
    <add_directory>
    src/test/com/thoughtworks/damagecontrolled
    </add_directory>
    <add_file>
    src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java
    </add_file>
    </summary>
</patch>
EOF

    def test_should_parse_CHANGESET_to_changeset
      parser = DarcsLogParser.new
      changeset = parser.parse_changeset(StringIO.new(CHANGESET))

      assert_equal("imported\nsources", changeset.message)
      assert_equal('', changeset.revision)
      assert_equal("tester@test.net", changeset.developer)
      assert_equal(Time.utc(2005,3,27,20,35,34), changeset.time)
      assert_equal(4, changeset.length)
    
      assert_equal("build.xml", changeset[0].path)
      assert_equal(Change::ADDED, changeset[0].status)
    
      assert_equal("project.xml", changeset[1].path)
      assert_equal(Change::ADDED, changeset[1].status)
   
      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[2].path)
      assert_equal(Change::ADDED, changeset[2].status)
    
      assert_equal("src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java", changeset[3].path)
      assert_equal(Change::ADDED, changeset[3].status)
    end

CHANGESETS = <<EOF
<changelog>
<patch author='tester@test.net' date='20050327204037' local_date='Sun Mar 27 16:40:37 AST 2005' inverted='False' hash='20050327204037-8fc3f-49f20f511eff452541c19cf8d4b188342f226c6c.gz'>
        <name>something nice</name>
        <comment>
        changed
something

        </comment>
    <summary>
    <modify_file>
    build.xml<removed_lines num='1'/><added_lines num='2'/>
    </modify_file>
    <modify_file>
    src/java/com/thoughtworks/damagecontrolled/Thingy.java<removed_lines num='1'/><added_lines num='2'/>
    </modify_file>
    </summary>
</patch>
<patch author='tester@test.net' date='20050327203534' local_date='Sun Mar 27 16:35:34 AST 2005' inverted='False' hash='20050327203534-4d520-baeeafb062e7f0d72ce740e1e1f5e6a203321ab4.gz'>
        <name>something nice</name>
        <comment>
        imported
sources
        </comment>
    <summary>
    <add_file>
    build.xml
    </add_file>
    <add_file>
    project.xml
    </add_file>
    <add_directory>
    src
    </add_directory>
    <add_directory>
    src/java
    </add_directory>
    <add_directory>
    src/java/com
    </add_directory>
    <add_directory>
    src/java/com/thoughtworks
    </add_directory>
    <add_directory>
    src/java/com/thoughtworks/damagecontrolled
    </add_directory>
    <add_file>
    src/java/com/thoughtworks/damagecontrolled/Thingy.java
    </add_file>
    <add_directory>
    src/test
    </add_directory>
    <add_directory>
    src/test/com
    </add_directory>
    <add_directory>
    src/test/com/thoughtworks
    </add_directory>
    <add_directory>
    src/test/com/thoughtworks/damagecontrolled
    </add_directory>
    <add_file>
    src/test/com/thoughtworks/damagecontrolled/ThingyTestCase.java
    </add_file>
    </summary>
</patch>
</changelog>
EOF

    def test_should_parse_CHANGESETS_to_changesets
      parser = DarcsLogParser.new
      changesets = parser.parse_changesets(StringIO.new(CHANGESETS))
      assert_equal(2, changesets.length)
      changeset = changesets[0]

      assert_equal("build.xml", changeset[0].path)
      assert_equal(Change::MODIFIED, changeset[0].status)

      assert_equal("src/java/com/thoughtworks/damagecontrolled/Thingy.java", changeset[1].path)
      assert_equal(Change::MODIFIED, changeset[1].status)
    end

    def test_should_parse_CHANGESET_to_changesets
      parser = DarcsLogParser.new
      changesets = parser.parse_changesets(StringIO.new(CHANGESET))
      assert_equal(1, changesets.length)
    end
  end
end

