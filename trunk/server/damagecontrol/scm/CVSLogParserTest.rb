require 'test/unit'
require 'stringio'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/scm/CVSLogParser'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class CVSLogParserTest < Test::Unit::TestCase
  
    include FileUtils
    
    def setup
      @parser = CVSLogParser.new(nil)
      @parser.cvspath = "/scm/damagecontrol"
      @parser.cvsmodule = "damagecontrol"
    end
    
    def teardown
      assert(!@parser.had_error?, "parser had errors") unless @parser.nil?
    end
    
    def test_read_log_entry
      assert_equal("blahblah\n", CVSLogParser.new(StringIO.new("blahblah\n============\nubbaubba\n===========")).next_log_entry)
      assert_equal(nil, CVSLogParser.new(StringIO.new("")).next_log_entry)
      assert_equal(nil, CVSLogParser.new(StringIO.new("============\n===========")).next_log_entry)
    end
    
    def test_parses_entire_log_into_changesets
      File.open("#{damagecontrol_home}/testdata/cvs-test.log") do |io|
        @parser = CVSLogParser.new(io)
        changesets = @parser.parse_changesets
        
        assert_equal(18, changesets.length)
        assert_match(/o YAML config \(BuildBootstrapper\)/, changesets[2].message)
        assert_match(/removed some output/, changesets[17].message)
      end
    end
    
    def test_parse_changes
      changesets = ChangeSets.new
      @parser.parse_changes(LOG_ENTRY, changesets)
      assert_equal(4, changesets.length)
      assert_equal("src/ruby/damagecontrol/BuildExecutorTest.rb", changesets[0][0].path)
      assert_match(/linux-windows galore/, changesets[2][0].message)
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

  LOG_ENTRY_WITH_DELETED_FILE = <<EOF
RCS file: /scm/damagecontrol/damagecontrol/server/damagecontrol/Attic/codehaus.rb,v
Working file: server/damagecontrol/codehaus.rb
head: 1.23
branch:
locks: strict
access list:
keyword substitution: kv
total revisions: 23;  selected revisions: 1
description:
----------------------------
revision 1.23
date: 2004/07/13 07:56:26;  author: tirsen;  state: dead;  lines: +0 -0
remove username check (doesn't work on beaver)
I do really want to see the url in irc, it's very, very convenient. thank you very much ;-)
EOF

    def test_can_parse_changes_with_deleted_file
      changesets = ChangeSets.new
      @parser.parse_changes(LOG_ENTRY_WITH_DELETED_FILE, changesets)
      assert_equal(1, changesets.length)
      assert_equal("server/damagecontrol/codehaus.rb", changesets[0][0].path)
      assert_equal(Change::DELETED, changesets[0][0].status)
    end
    
    def test_log_from_e2e_test
      @parser = CVSLogParser.new(StringIO.new(LOG_FROM_E2E_TEST))
      changesets = @parser.parse_changesets
      assert_equal(2, changesets.length)
      assert_match(/foo/, changesets[0].message)
      assert_match(/bar/, changesets[1].message)
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
total revisions: 1; selected revisions: 1
description:
EOF

    def test_can_parse_LOG_FROM_05_07_2004_19_41
      @parser = CVSLogParser.new(StringIO.new(LOG_FROM_05_07_2004_19_41))
      assert_equal(11, @parser.split_entries(LOG_FROM_05_07_2004_19_41).size)
      assert_equal("server/damagecontrol/scm/CVS.rb", @parser.parse_path(@parser.split_entries(LOG_FROM_05_07_2004_19_41)[0]))
      changesets = @parser.parse_changesets
         
      #puts changesets.format(CHANGESET_TEXT_FORMAT, Time.new.utc)
     
      assert_equal(9, changesets.length)
      expected_change = Change.new
      expected_change.path = "server/damagecontrol/scm/CVS.rb"
      expected_change.developer = "tirsen"
      expected_change.message = "fixed some stuff in the log parser\n"
      expected_change.revision = "1.18"
      expected_change.time = Time.utc(2004, 7, 5, 9, 38, 21)
      
      assert_equal(expected_change, changesets[0][1])
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

LOG_ENTRY_FROM_06_07_2004_19_25_1 = <<EOF
RCS file: /home/projects/jmock/scm/jmock/core/src/test/jmock/core/testsupport/MockInvocationMat
  V1_0_1: 1.4
  V1_0_0: 1.4
  V1_0_0_RC1: 1.4
  v1_0_0_RC1: 1.4
  before_removing_features_deprecated_pre_1_0_0: 1.1
keyword substitution: kv
total revisions: 4; selected revisions: 0
description:

EOF

    def test_can_parse_LOG_ENTRY_FROM_06_07_2004_19_25_1
      @parser.cvspath = "/home/projects/jmock/scm/jmock"
      @parser.cvsmodule = "core"
      assert_equal("src/test/jmock/core/testsupport/MockInvocationMat", @parser.parse_path(LOG_ENTRY_FROM_06_07_2004_19_25_1))
    end
    
LOG_ENTRY_FROM_06_07_2004_19_19 = <<EOF
Working file: lib/xmlrpc/datetime.rb
head: 1.1
branch:
locks: strict
access list:
symbolic names:
  BEFORE_CENTRAL_REFACTORING: 1.1
keyword substitution: kv
total revisions: 1; selected revisions: 0
description:

EOF

    def test_can_parse_LOG_ENTRY_FROM_06_07_2004_19_19
      assert_equal("lib/xmlrpc/datetime.rb", @parser.parse_path(LOG_ENTRY_FROM_06_07_2004_19_19))
    end
    
LOG_ENTRY_FROM_06_07_2004_19_25_2 = <<EOF
RC
Working file: website/templates/logo.gif
head: 1.2
branch:
locks: strict
access list:
symbolic names:
  steves_easymock: 1.2.0.2
  Root_steves_easymock: 1.2
  V1_0_1: 1.2
  V1_0_0: 1.2
  V1_0_0_RC1: 1.2
  before_removing_features_deprecated_pre_1_0_0: 1.2
  pre-hotmock-syntax-change: 1.2
keyword substitution: b
total revisions: 2; selected revisions: 0
description:

EOF

    def test_can_parse_LOG_ENTRY_FROM_06_07_2004_19_25_2
      assert_equal("website/templates/logo.gif", @parser.parse_path(LOG_ENTRY_FROM_06_07_2004_19_25_2))
    end

# stand in picocontainer's java folder
# cvs log -d"2003/07/25 12:38:41<=2004/07/08 12:38:41" build.xml
LOG_WITH_DELETIONS= <<EOF
RCS file: /home/projects/picocontainer/scm/java/Attic/build.xml,v
Working file: build.xml
head: 1.11
branch:
locks: strict
access list:
symbolic names:
        MERGE_CONTAINER_AND_REGISTRY_REFACTORING_BRANCH: 1.10.0.2
        BEFORE_MERGE_CONTAINER_AND_REGISTRY_REFACTORING_TAG: 1.10
        BEFORE_MULTIPLE_CONSTRUCTORS: 1.10
keyword substitution: kv
total revisions: 11;    selected revisions: 2
description:
----------------------------
revision 1.11
date: 2003/10/13 00:04:54;  author: rinkrank;  state: dead;  lines: +0 -0
Obsolete
----------------------------
revision 1.10
date: 2003/07/25 16:32:39;  author: rinkrank;  state: Exp;  lines: +1 -1
fixed broken url (NANO-8)
=============================================================================
EOF

    def test_can_parse_LOG_WITH_DELETIONS
      @parser = CVSLogParser.new(StringIO.new(LOG_WITH_DELETIONS))
      changesets = @parser.parse_changesets
      assert_equal(2, changesets.length)

      changeset_delete = changesets[0]
      assert_equal("MAIN:rinkrank:20031013000454", changeset_delete.revision)
      assert_equal(Time.utc(2003,10,13,00,04,54,0), changeset_delete.time)
      assert_equal("Obsolete\n", changeset_delete.message)
      assert_equal("rinkrank", changeset_delete.developer)
      assert_equal(1, changeset_delete.length)
      assert_equal("build.xml", changeset_delete[0].path)
      assert_equal("1.11", changeset_delete[0].revision)
      assert_equal("1.10", changeset_delete[0].previous_revision)
      assert(Change::DELETED, changeset_delete[0].status)

      changeset_fix_url = changesets[1]
      assert_equal("MAIN:rinkrank:20030725163239", changeset_fix_url.revision)
      assert_equal(Time.utc(2003,07,25,16,32,39,0), changeset_fix_url.time)
      assert_equal("fixed broken url (NANO-8)\n", changeset_fix_url.message)
      assert_equal("rinkrank", changeset_fix_url.developer)
      assert_equal(1, changeset_fix_url.length)
      assert_equal("build.xml", changeset_fix_url[0].path)
      assert_equal("1.10", changeset_fix_url[0].revision)
      assert_equal("1.9", changeset_fix_url[0].previous_revision)
      assert_equal(Change::MODIFIED, changeset_fix_url[0].status)
    end

LOG_WITH_MISSING_ENTRIES = <<EOF
RCS file: /cvsroot/damagecontrol/damagecontrol/Attic/build.xml,v
Working file: build.xml
head: 1.2
branch:
locks: strict
access list:
symbolic names:
  initial-import: 1.1.1.1
  mgm: 1.1.1
keyword substitution: kv
total revisions: 3; selected revisions: 0
description:
=============================================================================

RCS file: /cvsroot/damagecontrol/damagecontrol/maven.xml,v
Working file: maven.xml
head: 1.2
branch:
locks: strict
access list:
symbolic names:
keyword substitution: kv
total revisions: 2; selected revisions: 0
description:
=============================================================================
EOF

    def test_can_parse_LOG_WITH_MISSING_ENTRIES
      @parser = CVSLogParser.new(StringIO.new(LOG_WITH_MISSING_ENTRIES))
      changesets = @parser.parse_changesets
      assert_equal(0, changesets.length)
    end
  
LOG_WITH_NEW_AND_OLD_FILE = <<EOF
RCS file: /home/projects/damagecontrol/scm/damagecontrol/dummy.txt,v
Working file: dummy.txt
head: 1.1
branch:
locks: strict
access list:
keyword substitution: kv
total revisions: 1;     selected revisions: 1
description:
----------------------------
revision 1.1
date: 2004/07/13 21:50:59;  author: rinkrank;  state: Exp;
Debug. Need to see what the log looks like for a new file.
=============================================================================

RCS file: /home/projects/damagecontrol/scm/damagecontrol/license.txt,v
Working file: license.txt
head: 1.4
branch:
locks: strict
access list:
keyword substitution: kv
total revisions: 4;     selected revisions: 4
description:
----------------------------
revision 1.4
date: 2004/07/10 17:41:14;  author: rinkrank;  state: Exp;  lines: +2 -2
typo
----------------------------
revision 1.3
date: 2004/07/10 17:38:22;  author: rinkrank;  state: Exp;  lines: +2 -2
fixed http://jira.codehaus.org/browse/DC-123
----------------------------
revision 1.2
date: 2004/07/04 02:39:48;  author: rinkrank;  state: Exp;  lines: +1 -1
doherss
----------------------------
revision 1.1
date: 2004/07/02 08:42:51;  author: tirsen;  state: Exp;
installer!!!!!! it's getting close to release!!!
=============================================================================
EOF

    def test_can_distinguish_new_file_from_old_file
      @parser = CVSLogParser.new(StringIO.new(LOG_WITH_NEW_AND_OLD_FILE))
      changesets = @parser.parse_changesets

      new_file = changesets[0][0] 
      assert_equal(Change::ADDED, new_file.status)

      old_file = changesets[1][0] 
      assert_equal(Change::MODIFIED, old_file.status)
    end

  end
end
