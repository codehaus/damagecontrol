require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/scm/SCMFactory'
require 'damagecontrol/web/InstallTriggerServlet'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'
require 'test/unit'

module DamageControl
  class InstallTriggerServletTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting
    
    def setup
      @project_config_repository = ProjectConfigRepository.new(ProjectDirectories.new(new_temp_dir), SCMFactory.new, "")
      @servlet = InstallTriggerServlet.new(@project_config_repository, "")
      @project_config_repository.new_project("myprojectname")
    end

    def test_install_trigger
      result = do_request("project_name" => "myprojectname") do
        @servlet.default_action
      end
      assert_match(/myprojectname/i, result)
    end

    def test_do_install_trigger
      result = do_request("project_name" => "myprojectname") do
        @servlet.do_install_trigger
      end
      assert_match(/success/i, result)
      assert_match(/myprojectname/i, result)
    end
    
  end
end