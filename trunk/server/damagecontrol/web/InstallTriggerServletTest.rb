require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/web/InstallTriggerServlet'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'
require 'test/unit'

module DamageControl
  class InstallTriggerServletTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting

    def test_install_trigger
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir))
      servlet = InstallTriggerServlet.new(project_config_repository, "")
      result = do_request("project_name" => "myprojectname") do
        servlet.default_action
      end
      #assert_match(/install trigger/i, result)
      #assert_match(/do_install_trigger/i, result)
      #assert_match(/myprojectname/i, result)
    end

    def test_do_install_trigger
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir))
      servlet = InstallTriggerServlet.new(project_config_repository, "")
      result = do_request("project_name" => "project") do
        servlet.do_install_trigger
      end
      #assert_match(/success/i, result)
      #assert_match(/myprojectname/i, result)
    end
    
  end
end