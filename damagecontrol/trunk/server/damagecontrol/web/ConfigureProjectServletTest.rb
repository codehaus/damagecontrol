require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/web/ConfigureProjectServlet'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'
require 'test/unit'

require 'damagecontrol/scm/NoSCMWebConfigurator'
require 'damagecontrol/scm/CVSWebConfigurator'

require 'damagecontrol/scm/ScarabWebConfigurator'
require 'damagecontrol/scm/BugzillaWebConfigurator'

module DamageControl
  class ConfigureProjectServletTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting

    def test_store_configuration
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir), "")
      servlet = ConfigureProjectServlet.new(project_config_repository, [NoSCMWebConfigurator, CVSWebConfigurator], [ScarabWebConfigurator, BugzillaWebConfigurator], "a_url")

      query_params = {
        "project_name" => "myprojectname", 
        "scm_id" => CVS.name, 
        "cvsroot" => "mycvsroot",
        "tracking_id" => Bugzilla.name, 
        "bugzilla_url" => "http://www.bugzilla.org/"
      }
      result = do_request("/myprojectname", query_params) do
        servlet.store_configuration
      end
      assert(project_config_repository.project_exists?("myprojectname"))
      project_config = project_config_repository.project_config("myprojectname")
      assert_equal(CVS, project_config['scm'].class)
      assert_equal("mycvsroot", project_config['scm'].cvsroot)
      assert_equal(Bugzilla, project_config['tracking'].class)
      assert_equal("http://www.bugzilla.org/", project_config['tracking'].bugzilla_url)
    end
    
  end
end