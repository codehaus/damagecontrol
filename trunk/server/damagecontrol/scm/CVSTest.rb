require 'test/unit'
require 'damagecontrol/scm/GenericSCMTests'
require 'damagecontrol/scm/CVS'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class CVSTest < Test::Unit::TestCase
    
    include FileUtils
    include GenericSCMTests
    
    def create_scm(repository_dir, path)
      LocalCVS.new(repository_dir, path)
    end
  
    def test_can_build_a_cvs_rdiff_command_for_retrieving_the_changes_between_two_dates
      time_before = Time.utc(2004,01,01,12,00,00) 
      time_after = Time.utc(2005,01,01,12,00,00) 
      cvs = create_cvs(":local:repo", "module")
      assert_equal("log -N -S -d\"2004-01-01 12:00:00 UTC<=2005-01-01 12:00:00 UTC\" foo bar",
        cvs.new_changes_command(time_before, time_after, ["foo","bar"]))
      assert_equal("log -N -d\"2004-01-01 12:00:00 UTC<=2005-01-01 12:00:00 UTC\" foo bar",
        cvs.old_changes_command(time_before, time_after, ["foo","bar"]))
    end
    
    def create_cvs(cvsroot, cvsmodule, checkout_dir=new_temp_dir)
      cvs = CVS.new
      cvs.cvsroot = cvsroot
      cvs.cvsmodule = cvsmodule
      cvs
    end
    
    def jons_birthday
      Time.utc(1977, 06, 15, 12, 00, 00)
    end

    def test_checkout_command
      cvs = create_cvs(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol")
      assert_equal(
        'checkout -D "1977-06-15 12:00:00 UTC" -d target_dir damagecontrol', \
        cvs.checkout_command(jons_birthday, "target_dir"))
    end
    
    def test_update_command
      cvs = create_cvs(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", "damagecontrol")
      assert_equal(
        "update -D \"1977-06-15 12:00:00 UTC\" -d -P -A",
        cvs.update_command(jons_birthday))
    end
    
    def test_invalid_cvs_command_raises_error
      cvs = create_cvs("cvsroot", "cvsmodule")
      assert_raises(Pebbles::ProcessFailedException, "invalid cvs command did not raise error") do
        cvs.cvs(".", "invalid_command") { |line| }
      end
    end
    
  end
end
