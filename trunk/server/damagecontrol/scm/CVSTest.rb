require 'test/unit'
require 'ftools'
require 'stringio'
require 'fileutils'
require 'damagecontrol/scm/CVS'
require 'webrick'

module DamageControl
  class CVSTest < Test::Unit::TestCase
    include ::FileUtils
    include FileUtils
  
    def setup
      @cvs = CVS.new
    end
    
    def test_modifiying_one_file_produce_correct_changeset
      # create a couple of temp directories and clean them up
      testrepo = File.expand_path("#{damagecontrol_home}/target/cvstestrepo")
      rm_rf(testrepo)
      testcheckout = File.expand_path("#{damagecontrol_home}/target/cvstestcheckout")
      rm_rf(testcheckout)
      
      # create cvs repo and import test project, check it out afterwards
      spec = ":local:#{testrepo}:damagecontrolled"
      create_repo(testrepo)
      import_damagecontrolled(spec)
      @cvs.checkout(spec, testcheckout)
      
      # modify file and commit it
      change_file("#{testcheckout}/build.xml")
      time_before = Time.now.utc
      sleep(1)
      @cvs.commit(testcheckout, "changed something")
      sleep(1)
      time_after = Time.now.utc
      
      # check that we now have one more change
      changes = @cvs.changes(spec, testcheckout, time_before, time_after)
      assert_equal(1, changes.length)
      mod = changes[0]
      assert_equal("build.xml", mod.path)
      assert_equal("changed something\n", mod.message)
    end
    
    def test_can_build_a_cvs_rdiff_command_for_retrieving_the_changes_between_two_dates
      time_before = Time.gm(2004,01,01,12,00,00) 
      time_after = Time.gm(2004,01,01,13,00,00)
      spec = ":local:repo:module"
      assert_equal("log -d\"2004-01-01 12:00:00 UTC<=2004-01-01 13:00:00 UTC\"",
        @cvs.changes_command(time_before, time_after))
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
    def test_parse_local_unix_spec
      protocol = "local"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      spec     = ":#{protocol}:#{path}:#{mod}"

      assert_equal([protocol, nil, nil, path, mod], @cvs.parse_spec(spec))
      assert_equal(":local:/cvsroot/damagecontrol", @cvs.cvsroot(spec))
    end

    def test_parse_local_windows_spec
      protocol = "local"
      path     = "C:\\pling\\plong"
      mod      = "damagecontrol"

      spec     = ":#{protocol}:#{path}:#{mod}"

      assert_equal([protocol, nil, nil, path, mod], @cvs.parse_spec(spec))
      assert_equal(":local:C:\\pling\\plong", @cvs.cvsroot(spec))
    end
    
    def test_tokens
      spec = ":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"
      assert_equal("pserver",                @cvs.protocol(spec))
      assert_equal("anonymous",              @cvs.user(spec))
      assert_equal("cvs.codehaus.org",       @cvs.host(spec))
      assert_equal("/cvsroot/damagecontrol", @cvs.path(spec))
      assert_equal("damagecontrol",          @cvs.mod(spec))
    end
    
    def test_parse_pserver_spec
      protocol = "pserver"
      user     = "anonymous"
      host     = "cvs.codehaus.org"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      spec     = ":#{protocol}:#{user}@#{host}:#{path}:#{mod}"

      assert_equal([protocol, user, host, path, mod], @cvs.parse_spec(spec))
      assert_equal(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", @cvs.cvsroot(spec))
    end
    
    def test_checkout_command
      root = to_os_path("/some/where")
      assert_equal(
        "-d:pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol checkout damagecontrol", \
        @cvs.checkout_command(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol", "/some/where"))
    end
    
    def test_update_command
      assert_equal(
        "-d:pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol update -d -P", \
        @cvs.update_command(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"))
    end
    
    def test_does_not_handle_starteam_path
      assert(!@cvs.handles_spec?("starteam://username:password@server/project/view/folder"))
    end
    
    def test_install_trigger
      basedir = new_temp_dir
      testrepo = File.expand_path("#{basedir}/cvstestrepo")
      rm_rf(testrepo)
      testcheckout = File.expand_path("#{basedir}/cvstestcheckout/CVSROOT")
      rm_rf(testcheckout)
      
      project_name = "DamageControlled"
      spec = ":local:#{testrepo}:damagecontrolled"
      system("cvs init #{testrepo}")
      build_command = "echo hello"
      nag_email = "maillist@project.bar"

      create_repo(testrepo)
      @cvs.install_trigger(
        testcheckout,
        project_name,
        spec,
        "http://localhost:4713/private/xmlrpc"
      ) { |output|
        puts output
      }

      assert_match(/damagecontrolled ruby (.*)dctrigger.rb http:\/\/localhost:4713\/private\/xmlrpc DamageControlled/, File.new("#{testcheckout}/loginfo").read)
    end
    
    def test_invalid_cvs_command_raises_error
      assert_raises(SCMError, "invalid cvs command did not raise error") do
        @cvs.cvs("invalid_command") { |line| }
      end
    end

  private
  
    def create_repo(dir)
      with_working_dir(dir) do
        system("cvs -d:local:#{dir} init")
      end
    end
    
    def import_damagecontrolled(spec)
      with_working_dir("#{damagecontrol_home}/testdata/damagecontrolled") do
        cmd = "cvs -d#{@cvs.cvsroot(spec)} -q import -m \"\" #{@cvs.mod(spec)} dc-vendor dc-release"
        system(cmd)
      end
    end
  end


  class CVSLogParserTest < Test::Unit::TestCase
  
    include FileUtils
    
    def setup
      @parser = CVSLogParser.new
    end
    
    def test_extracts_log_entries
      File.open("#{damagecontrol_home}/testdata/cvs-test.log") do |io|
        changeset = @parser.parse_log(io)
        assert_equal(46, changeset.length)
        assert_match(/self test/, changeset[0].message)
        assert_match(/o YAML config \(BuildBootstrapper\)/, changeset[45].message)
        assert_match(/EmailPublisher/, changeset[45].message)
      end
    end
    
    
    def test_parse_modifications
      modifications = @parser.parse_modifications(LOG_ENTRY)
      assert_equal(4, modifications.length)
      assert_equal("/cvsroot/damagecontrol/damagecontrol/src/ruby/damagecontrol/BuildExecutorTest.rb", modifications[0].path)
      assert_match(/linux-windows galore/, modifications[2].message)
    end
    

    def test_parse_modification
      modification = @parser.parse_modification(MODIFICATION_ENTRY)
      assert_equal("1.20", modification.revision)
      assert_equal("2003/11/09 17:53:37", modification.time)
      assert_equal("tirsen", modification.developer)
      assert_match(/Quiet period is configurable for each project/, modification.message)
    end
    
    def test_removes_cvsroot_and_module_from_paths_when_specified
      @parser.cvspath = "/cvsroot/damagecontrol"
      @parser.cvsmodule = "damagecontrol"
      modifications = @parser.parse_modifications(LOG_ENTRY)
      assert_equal("src/ruby/damagecontrol/BuildExecutorTest.rb", modifications[0].path)
      assert_match(/linux-windows galore/, modifications[2].message)
    end
    
    def test_can_split_entries_separated_by_line_of_dashes
      entries = @parser.split_entries(LOG_ENTRY)
      assert_equal(5, entries.length)
      assert_equal(MODIFICATION_ENTRY, entries[1])
    end
    
    def test_log_from_e2e_test
      io = StringIO.new(LOG_FROM_E2E_TEST)
      changeset = @parser.parse_log(io)
      assert_equal(2, changeset.length)
      assert_match(/foo/, changeset[0].message)
      assert_match(/bar/, changeset[1].message)
    end

    MODIFICATION_ENTRY = <<-EOF
revision 1.20
date: 2003/11/09 17:53:37;  author: tirsen;  state: Exp;  lines: +3 -4
Quiet period is configurable for each project
EOF

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

RCS file: /cvsroot/damagecontrol/damagecontrol/src/ruby/damagecontrol/BuildExecutorTest.rb,v
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

  end

end
