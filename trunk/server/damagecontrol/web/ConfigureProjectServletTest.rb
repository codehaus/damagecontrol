require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/web/ConfigureProjectServlet'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'
require 'test/unit'

module DamageControl
  class ConfigureProjectServletTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting

    def test_configure
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir))
      servlet = ConfigureProjectServlet.new(project_config_repository, [])
      result = do_request("project_name" => "myprojectname") do
        servlet.default_action
      end
    end

    def test_store_configuration
      project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir))
      servlet = ConfigureProjectServlet.new(project_config_repository, [])
      result = do_request("project_name" => "myprojectname") do
        servlet.store_configuration
      end
    end
    
  end
end