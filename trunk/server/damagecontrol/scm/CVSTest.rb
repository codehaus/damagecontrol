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
  
    def test_modifiying_one_file_produce_correct_changeset
      # create a couple of temp directories and clean them up
      basedir = new_temp_dir
      testrepo = File.expand_path("#{basedir}/repo")
      rm_rf(testrepo)
      testcheckout = File.expand_path("#{basedir}/work")
      rm_rf(testcheckout)
      
      # create cvs repo and import test project, check it out afterwards
      cvs = CVS.new(":local:#{testrepo}", "damagecontrolled", testcheckout)
      create_repo(testrepo)
      import_damagecontrolled(cvs)
      cvs.checkout
      
      # modify file and commit it
      change_file("#{cvs.working_dir}/build.xml")
      sleep(1)
      time_before = Time.now.utc
      cvs.commit("changed something")
      sleep(1)
      time_after = Time.now.utc
      
      # check that we now have one more change
      changes = cvs.changes(time_before, time_after)

puts "CHANGES"
changes.each do |modif|
  puts "#{modif.developer} : #{modif.path} : #{modif.time}"
end

      assert_equal(1, changes.length)
      mod = changes[0]
      assert_equal("build.xml", mod.path)
      assert_equal("changed something", mod.message)
    end
    
    def test_can_build_a_cvs_rdiff_command_for_retrieving_the_changes_between_two_dates
      time_before = Time.gm(2004,01,01,12,00,00) 
      time_after = Time.gm(2004,01,01,13,00,00)
      cvs = CVS.new(":local:repo", "module", nil)
      assert_equal("log -d\"2004-01-01 12:00:00 UTC<=2004-01-01 13:00:00 UTC\"",
        cvs.changes_command(time_before, time_after))
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
    def test_parse_local_unix_cvsroot
      protocol = "local"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      cvs      = CVS.new(":#{protocol}:#{path}", "#{mod}", nil)

      assert_equal(protocol, cvs.protocol)
      assert_equal(nil,      cvs.user)
      assert_equal(nil,      cvs.host)
      assert_equal(path,     cvs.path)
      assert_equal(mod,      cvs.mod)
    end

    def test_parse_local_windows_cvsroot
      protocol = "local"
      path     = "C:\\pling\\plong"
      mod      = "damagecontrol"

      cvs      = CVS.new(":#{protocol}:#{path}", "#{mod}", nil)

      assert_equal(protocol, cvs.protocol)
      assert_equal(nil,      cvs.user)
      assert_equal(nil,      cvs.host)
      assert_equal(path,     cvs.path)
      assert_equal(mod,      cvs.mod)
    end
    
    def test_parse_pserver_unix_cvsroot
      protocol = "pserver"
      user     = "anonymous"
      host     = "beaver.codehaus.org"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      cvs      = CVS.new(":#{protocol}:#{user}@#{host}:#{path}", "#{mod}", nil)

      assert_equal(protocol, cvs.protocol)
      assert_equal(user,     cvs.user)
      assert_equal(host,     cvs.host)
      assert_equal(path,     cvs.path)
      assert_equal(mod,      cvs.mod)
    end
    
    def jons_birthday
      Time.utc(1977, 06, 15, 12, 00, 00)
    end

    def test_checkout_command
      cvs = CVS.new(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol", nil)
      assert_equal(
        '-d:pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol checkout -D "1977-06-15 12:00:00 UTC" damagecontrol', \
        cvs.checkout_command(jons_birthday))
    end
    
    def test_update_command
      cvs = CVS.new(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol", nil)
      assert_equal(
        '-d:pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol update -D "1977-06-15 12:00:00 UTC" -d -P', \
        cvs.update_command(jons_birthday))
    end
    
LOGINFO_WITH_TWO_TRIGGERS = <<-EOF
# or
#DEFAULT (echo ""; id; echo %{sVv}; date; cat) >> $CVSROOT/CVSROOT/commitlog
pf ruby dctrigger.rb http://localhost:4713/private/xmlrpc pizzaface
p ruby dctrigger.rb http://localhost:4713/private/xmlrpc pizza
#b ruby dctrigger.rb http://localhost:4713/private/xmlrpc bongo
EOF

LOGINFO_WITH_OLD_TRIGGER = <<-EOF
old cat $CVSROOT/CVSROOT/damagecontrol-old.conf | nc builds.codehaus.org 4711
EOF

LOGINFO_WITH_ONE_TRIGGER = <<-EOF
# or
#DEFAULT (echo ""; id; echo %{sVv}; date; cat) >> $CVSROOT/CVSROOT/commitlog
pf ruby dctrigger.rb http://localhost:4713/private/xmlrpc pizzaface
# Disabled by DamageControl on June 27, 2004
#p ruby dctrigger.rb http://localhost:4713/private/xmlrpc pizza
#b ruby dctrigger.rb http://localhost:4713/private/xmlrpc bongo
EOF

    def test_trigger_installed_should_detect_active_trigger_lines
      cvs = CVS.new(nil, nil, nil)
      assert(cvs.trigger_in_string?(LOGINFO_WITH_TWO_TRIGGERS, "pizza"))
      assert(!cvs.trigger_in_string?(LOGINFO_WITH_TWO_TRIGGERS, "somethingelse"))
      assert(!cvs.trigger_in_string?(LOGINFO_WITH_TWO_TRIGGERS, "bongo"))
    end
    
    def test_trigger_uninstall_should_uninstall_correct_line
      cvs = CVS.new(nil, nil, nil)
      uninstalled = cvs.disable_trigger_from_string(LOGINFO_WITH_TWO_TRIGGERS, "pizza", Time.utc(2004, 6, 27, 0, 0, 0, 0))
      assert_equal(LOGINFO_WITH_ONE_TRIGGER, uninstalled)
    end
    
    def test_old_style_triggers_should_be_recognised
      cvs = CVS.new(nil, nil, nil)
      assert(cvs.trigger_in_string?(LOGINFO_WITH_OLD_TRIGGER, "blah"))
    end
    
    def test_install_uninstall_install_should_add_four_lines_to_loginfo
      basedir = new_temp_dir

      testrepo = File.expand_path("#{basedir}/repo")
      rm_rf(testrepo)
      create_repo(testrepo)

      working_dir = File.expand_path("#{basedir}/work")
      rm_rf(working_dir)

      project_name = "OftenModified"
      cvs = CVS.new(":local:#{testrepo}", "often", working_dir)
      
      assert(!cvs.trigger_installed?(project_name))
      cvs.install_trigger(
        project_name,
        "http://localhost:4713/private/xmlrpc"
      )
      assert(cvs.trigger_installed?(project_name))
      cvs.uninstall_trigger(project_name)
      assert(!cvs.trigger_installed?(project_name))
      cvs.install_trigger(
        project_name,
        "http://localhost:4713/private/xmlrpc"
      )
      assert(cvs.trigger_installed?(project_name))

    end
    
    def test_invalid_cvs_command_raises_error
      cvs = CVS.new(nil, nil, nil)
      assert_raises(Exception, "invalid cvs command did not raise error") do
        cvs.cvs("invalid_command") { |line| }
      end
    end

  private
  
    def create_repo(dir)
      with_working_dir(dir) do
        system("cvs -d:local:#{dir} init")
      end
    end
    
    def import_damagecontrolled(cvs)
      with_working_dir("#{damagecontrol_home}/testdata/damagecontrolled") do
        cmd = "cvs -d#{cvs.cvsroot} -q import -m \"\" #{cvs.mod} dc-vendor dc-release"
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
