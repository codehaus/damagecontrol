require 'test/unit'
require 'ftools'
require 'stringio'
require 'fileutils'
require 'damagecontrol/scm/CVS'
require 'webrick'

module DamageControl
  class CVSLogParserTest < Test::Unit::TestCase
  
    include FileUtils
    
    def setup
      @parser = CVSLogParser.new
      @parser.cvspath = "/scm/damagecontrol"
      @parser.cvsmodule = "damagecontrol"
    end
    
    def teardown
      assert(!@parser.had_error?, "parser had errors")
    end
    
    def test_read_log_entry
      assert_equal("blahblah\n", @parser.read_log_entry(StringIO.new("blahblah\n============\nubbaubba\n===========")))
      assert_equal(nil, @parser.read_log_entry(StringIO.new("")))
      assert_equal(nil, @parser.read_log_entry(StringIO.new("============\n===========")))
    end
    
    def test_extracts_log_entries
      File.open("#{damagecontrol_home}/testdata/cvs-test.log") do |io|
        changeset = @parser.parse_changes_from_log(io)
        assert_equal(46, changeset.length)
        assert_match(/self test/, changeset[0].message)
        assert_match(/o YAML config \(BuildBootstrapper\)/, changeset[45].message)
        assert_match(/EmailPublisher/, changeset[45].message)
      end
    end
    
    def test_parse_changes
      changes = @parser.parse_changes(LOG_ENTRY)
      assert_equal(4, changes.length)
      assert_equal("src/ruby/damagecontrol/BuildExecutorTest.rb", changes[0].path)
      assert_match(/linux-windows galore/, changes[2].message)
    end
    
    def test_sets_previous_revision_to_one_before_the_current
      change = @parser.parse_change(CHANGE_ENTRY)
      assert_equal("1.20", change.revision)
      assert_equal("1.19", change.previous_revision)
    end
    
    def test_can_determine_previous_revisions_from_tricky_input
      assert_equal("2.2.1.1", @parser.determine_previous_revision("2.2.1.2"))
      assert_equal(nil, @parser.determine_previous_revision("2.2.1.1"))
    end

    def test_parse_change
      change = @parser.parse_change(CHANGE_ENTRY)
      assert_equal("1.20", change.revision)
      assert_equal(Time.utc(2003,11,9,17,53,37), change.time)
      assert_equal("tirsen", change.developer)
      assert_match(/Quiet period is configurable for each project/, change.message)
    end
    
    def test_removes_cvsroot_and_module_from_paths_when_specified
      changes = @parser.parse_changes(LOG_ENTRY)
      assert_equal("src/ruby/damagecontrol/BuildExecutorTest.rb", changes[0].path)
      assert_match(/linux-windows galore/, changes[2].message)
    end
    
    def test_can_split_entries_separated_by_line_of_dashes
      entries = @parser.split_entries(LOG_ENTRY)
      assert_equal(5, entries.length)
      assert_equal(CHANGE_ENTRY, entries[1])
    end
    
    CHANGE_ENTRY = <<-EOF
revision 1.20
date: 2003/11/09 17:53:37;  author: tirsen;  state: Exp;  lines: +3 -4
Quiet period is configurable for each project
EOF

    def test_log_from_e2e_test
      io = StringIO.new(LOG_FROM_E2E_TEST)
      changeset = @parser.parse_changes_from_log(io)
      assert_equal(2, changeset.length)
      assert_match(/foo/, changeset[0].message)
      assert_match(/bar/, changeset[1].message)
    end
    
    LOG_FROM_E2E_TEST = <<-EOF
=============================================================================

RCS file: C:\projects\damagecontrol\target\temp_e2e_1081547757\repository/e2eproject/build.bat,v
Working file: build.bat
head: 1.2
branch:
locks: strict
access list:
symbolic names:
keyword substitution: kv
total revisions: 2;     selected revisions: 2
description:
----------------------------
revision 1.2
date: 2004/04/09 21:56:47;  author: jtirsen;  state: Exp;  lines: +1 -1
foo
----------------------------
revision 1.1
date: 2004/04/09 21:56:12;  author: jtirsen;  state: Exp;
bar
=============================================================================EOF
EOF

    LOG_ENTRY = <<-EOF
=============================================================================

RCS file: /scm/damagecontrol/damagecontrol/src/ruby/damagecontrol/BuildExecutorTest.rb,v
Working file: src/ruby/damagecontrol/BuildExecutorTest.rb
head: 1.20
branch:
locks: strict
access list:
symbolic names:
keyword substitution: kv
total revisions: 20;    selected revisions: 4
description:
----------------------------
revision 1.20
date: 2003/11/09 17:53:37;  author: tirsen;  state: Exp;  lines: +3 -4
Quiet period is configurable for each project
----------------------------
revision 1.19
date: 2003/11/09 17:04:18;  author: tirsen;  state: Exp;  lines: +32 -2
Quiet period implemented for BuildExecutor, but does not yet handle multiple projects (builds are not queued as before)
----------------------------
revision 1.18
date: 2003/11/09 15:51:50;  author: rinkrank;  state: Exp;  lines: +1 -2
linux-windows galore
----------------------------
revision 1.17
date: 2003/11/09 15:00:06;  author: rinkrank;  state: Exp;  lines: +6 -8
o YAML config (BuildBootstrapper)
o EmailPublisher
=============================================================================
    EOF
    
    def test_can_parse_path
      assert_equal("testdata/damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java", 
        @parser.parse_path(LOG_ENTRY_FROM_05_07_2004_19_42))
    end
    
LOG_ENTRY_FROM_05_07_2004_19_42 = <<-EOF
RCS file: /scm/damagecontrol/damagecontrol/testdata/damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java,v
Working file: testdata/damagecontrolled/src/java/com/thoughtworks/damagecontrolled/Thingy.java
head: 1.1
branch:
locks: strict
access list:
symbolic names:
	BEFORE_CENTRAL_REFACTORING: 1.1
	RELEASE_0_1: 1.1
keyword substitution: kv
total revisions: 1;	selected revisions: 1
description:
EOF

    def test_can_parse_LOG_FROM_05_07_2004_19_41
      assert_equal(11, @parser.split_entries(LOG_FROM_05_07_2004_19_41).size)
      assert_equal("server/damagecontrol/scm/CVS.rb", @parser.parse_path(@parser.split_entries(LOG_FROM_05_07_2004_19_41)[0]))
      changes = @parser.parse_changes_from_log(StringIO.new(LOG_FROM_05_07_2004_19_41))
      assert_equal(10, changes.size)
      assert_equal(Change.new("server/damagecontrol/scm/CVS.rb", "tirsen", "fixed some stuff in the log parser", "1.18", Time.utc(2004, 7, 5, 9, 38, 21)),
        changes[1])
    end

LOG_FROM_05_07_2004_19_41 = <<-EOF

RCS file: /scm/damagecontrol/damagecontrol/server/damagecontrol/scm/CVS.rb,v
Working file: server/damagecontrol/scm/CVS.rb
head: 1.19
branch:
locks: strict
access list:
symbolic names:
        BEFORE_CENTRAL_REFACTORING: 1.1
keyword substitution: kv
total revisions: 19;    selected revisions: 19
description:
----------------------------
revision 1.19
date: 2004/07/05 09:41:51;  author: tirsen;  state: Exp;  lines: +1 -1
fixed some stuff in the log parser
----------------------------
revision 1.18
date: 2004/07/05 09:38:21;  author: tirsen;  state: Exp;  lines: +7 -6
fixed some stuff in the log parser
----------------------------
revision 1.17
date: 2004/07/05 09:09:44;  author: tirsen;  state: Exp;  lines: +2 -0
oops.... log parser can't actually log apparently, well, it can now...
----------------------------
revision 1.16
date: 2004/07/05 08:52:39;  author: tirsen;  state: Exp;  lines: +23 -26
refactorings in the web
fixed footer with css
some other cssing around
fixed cvs output so my irc client actually gives me a proper link I can click on
----------------------------
revision 1.15
date: 2004/07/04 18:04:38;  author: rinkrank;  state: Exp;  lines: +1 -1
debug debug
----------------------------
revision 1.14
date: 2004/07/04 17:44:36;  author: rinkrank;  state: Exp;  lines: +23 -8
improved error logging
----------------------------
revision 1.13
date: 2004/07/04 15:59:16;  author: rinkrank;  state: Exp;  lines: +1 -0
debugging cvs timestamps
----------------------------
revision 1.12
date: 2004/07/03 19:25:19;  author: rinkrank;  state: Exp;  lines: +20 -3
support for previous_revision in modifications
----------------------------
revision 1.11
date: 2004/07/02
CVS and CC refactorings. Improved parsing of trigger command line and bootstrapping
----------------------------
revision 1.1
date: 2003/10/04 12:04:14;  author: tirsen;  state: Exp;
Cleaned up the end-to-end test, did some more work on the CCLogPoller
EOF

LOG_ENTRY_FROM_06_07_2004_19_25 = <<EOF
RCS file: /home/projects/jmock/scm/jmock/core/src/test/jmock/core/testsupport/MockInvocationMat
	V1_0_1: 1.4
	V1_0_0: 1.4
	V1_0_0_RC1: 1.4
	v1_0_0_RC1: 1.4
	before_removing_features_deprecated_pre_1_0_0: 1.1
keyword substitution: kv
total revisions: 4;	selected revisions: 0
description:

EOF

    def test_can_parse_LOG_ENTRY_FROM_06_07_2004_19_25
      @parser.cvspath = "/home/projects/jmock/scm/jmock"
      @parser.cvsmodule = "core"
      assert_equal("src/test/jmock/core/testsupport/MockInvocationMat", @parser.parse_path(LOG_ENTRY_FROM_06_07_2004_19_25))
    end

  end

end
