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
      cvs = create_cvs(":local:#{testrepo}", "damagecontrolled", testcheckout)
      create_repo(testrepo)
      import_damagecontrolled(cvs)
      cvs.checkout
      
      # modify file and commit it
      sleep(1)
      time_before = Time.now.utc
      sleep(1)
      change_file("#{cvs.working_dir}/build.xml")
      cvs.commit("changed something")
      sleep(1)
      time_after = Time.now.utc
      
      # check that we now have one more change
      changes = cvs.changes(time_before, time_after)

      assert_equal(1, changes.length)
      mod = changes[0]
      assert_equal("build.xml", mod.path)
      assert_equal("changed something", mod.message)
    end
    
    def Xtest_can_build_a_cvs_rdiff_command_for_retrieving_the_changes_between_two_dates
      time_before = Time.utc(2004,01,01,12,00,00) 
      time_after = Time.utc(2004,01,01,13,00,00)
      cvs = CVS.new(":local:repo", "module", nil)
      assert_equal("log -d\"2004-01-01 12:00:00 UTC<=2004-01-01 13:00:00 UTC\"",
        cvs.changes_command(time_before, time_after))
    end
    
    def change_file(file)
      File.open(file, "w+") do |io|
        io.puts("changed\n")
      end
    end
    
    def create_cvs(cvsroot, cvsmodule, working_dir_root=new_temp_dir)
      CVS.new("cvsroot" => cvsroot, "cvsmodule" => cvsmodule, "working_dir_root" => working_dir_root)
    end
    
    def test_parse_local_unix_cvsroot
      protocol = "local"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      cvs      = create_cvs(":#{protocol}:#{path}", "#{mod}")

      assert_equal(protocol, cvs.protocol)
      assert_equal(nil,         cvs.user)
      assert_equal(nil,         cvs.host)
      assert_equal(path,      cvs.path)
      assert_equal(mod,       cvs.mod)
    end

    def test_parse_local_windows_cvsroot
      protocol = "local"
      path     = "C:\\pling\\plong"
      mod      = "damagecontrol"

      cvs      = create_cvs(":#{protocol}:#{path}", "#{mod}")

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

      cvs      = create_cvs(":#{protocol}:#{user}@#{host}:#{path}", "#{mod}")

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
      cvs = create_cvs(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol")
      assert_equal(
        '-d:pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol checkout -D "1977-06-15 12:00:00 UTC" damagecontrol', \
        cvs.checkout_command(jons_birthday))
    end
    
    def test_update_command
      cvs = create_cvs(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol")
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
      cvs = create_cvs("cvsroot", "cvsmodule")
      assert(cvs.trigger_in_string?(LOGINFO_WITH_TWO_TRIGGERS, "pizza"))
      assert(!cvs.trigger_in_string?(LOGINFO_WITH_TWO_TRIGGERS, "somethingelse"))
      assert(!cvs.trigger_in_string?(LOGINFO_WITH_TWO_TRIGGERS, "bongo"))
    end
    
    def test_trigger_uninstall_should_uninstall_correct_line
      cvs = create_cvs("cvsroot", "cvsmodule")
      uninstalled = cvs.disable_trigger_from_string(LOGINFO_WITH_TWO_TRIGGERS, "pizza", Time.utc(2004, 6, 27, 0, 0, 0, 0))
      assert_equal(LOGINFO_WITH_ONE_TRIGGER, uninstalled)
    end
    
    def test_old_style_triggers_should_be_recognised
      cvs = create_cvs("cvsroot", "cvsmodule")
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
      cvs = create_cvs(":local:#{testrepo}", "often", working_dir)
      
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
      cvs = create_cvs("cvsroot", "cvsmodule")
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
end
