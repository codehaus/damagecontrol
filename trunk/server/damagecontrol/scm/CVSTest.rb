require 'test/unit'
require 'damagecontrol/scm/GenericSCMTests'
require 'damagecontrol/scm/CVS'

module DamageControl
  class CVSTest < Test::Unit::TestCase
    
    include GenericSCMTests
    
    def create_scm
      LocalCVS.new(new_temp_dir, "damagecontrolled")
    end
  
    def test_can_build_a_cvs_rdiff_command_for_retrieving_the_changes_between_two_dates
      time_before = Time.utc(2004,01,01,12,00,00) 
      time_after = Time.utc(2004,01,01,13,00,00)
      cvs = CVS.new({"cvsroot" => ":local:repo", "cvsmodule" => "module", "checkout_dir" => "."})
      assert_equal("log -N -S -d\"2004-01-01 12:00:00 UTC<=2004-01-01 13:00:00 UTC\"",
        cvs.changes_command(time_before, time_after))
    end
    
    def create_cvs(cvsroot, cvsmodule, checkout_dir=new_temp_dir)
      CVS.new("cvsroot" => cvsroot, "cvsmodule" => cvsmodule, "checkout_dir" => checkout_dir)
    end
    
    def jons_birthday
      Time.utc(1977, 06, 15, 12, 00, 00)
    end

    def test_checkout_command
      cvs = create_cvs(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol")
      assert_equal(
        'checkout -D "1977-06-15 12:00:00 UTC" damagecontrol', \
        cvs.checkout_command(jons_birthday))
    end
    
    def test_update_command
      cvs = create_cvs(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol")
      assert_equal(
        'update -D "1977-06-15 12:00:00 UTC" -d -P', \
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
      cvs = create_scm
      cvs.create

      project_name = "OftenModified"
      
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
        cvs.cvs(cvs.checkout_dir, "invalid_command") { |line| }
      end
    end

  end
end
