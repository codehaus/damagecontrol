require 'test/unit'
require 'damagecontrol/scm/GenericSCMTests'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/scm/Changes'

module DamageControl
  class SVNTest < Test::Unit::TestCase
  
    include GenericSCMTests

    def create_scm
      LocalSVN.new(new_temp_dir, "damagecontrolled")
    end

    def Xtest_web_url_to_change_produces_working_copy_url_when_view_cvs_url_not_specified
      change = Change.new("testdata/log20030929145347.xml", "aslak", "easteregg", "r6", Time.new.utc)
      svn = LocalSVN.new(".", "damagecontrol")
      assert_equal("root/damagecontrol/checkout/damagecontrol/testdata/log20030929145347.xml",
        svn.web_url_to_change(change))
    end

    def Xtest_web_url_to_change_produces_view_cvs_url_url_when_view_cvs_url_specified
      change = Change.new("testdata/log20030929145347.xml", "aslak", "easteregg", "r6", Time.new.utc)
      change.previous_revision = "r5"
      config_map = {"checkout_dir" => "/some/where", "svnurl" => "svn://any/time/now", "svnprefix" => "now"}
      svn = SVN.new(config_map)
      svn.config_map["view_cvs_url"] = "http://cvs.damagecontrol.codehaus.org/"
      assert_equal("http://cvs.damagecontrol.codehaus.org/damagecontrol/testdata/log20030929145347.xml?r1=r5&r2=r6",
        svn.web_url_to_change(change))
    end
  end
end
