require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/web/ConfigureProjectServlet'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'
require 'test/unit'

require 'damagecontrol/scm/NoSCMWebConfigurator'
require 'damagecontrol/scm/CVSWebConfigurator'

module DamageControl
  class ConfigureProjectServletTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting

    def test_configure
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir), "")
      servlet = ConfigureProjectServlet.new(project_config_repository, [], "a_url")
      result = do_request("project_name" => "myprojectname") do
        servlet.default_action
      end
    end

    def test_store_configuration
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir), "")
      servlet = ConfigureProjectServlet.new(project_config_repository, [NoSCMWebConfigurator, CVSWebConfigurator], "a_url")
      result = do_request("project_name" => "myprojectname", "scm_id" => CVS.name, "cvsroot" => "mycvsroot") do
        servlet.store_configuration
      end
      assert(project_config_repository.project_exists?("myprojectname"))
      project_config = project_config_repository.project_config("myprojectname")
      assert_equal(CVS, project_config['scm'].class)
      assert_equal("mycvsroot", project_config['scm'].cvsroot)
    end
    
  end
end