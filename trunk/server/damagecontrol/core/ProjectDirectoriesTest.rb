require 'test/unit'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class ProjectDirectoriesTest < Test::Unit::TestCase
  
    include FileUtils
  
    def setup
      @basedir = new_temp_dir
    end

    def test_can_list_project_directories
      pd = ProjectDirectories.new(@basedir)
      assert_equal([], pd.project_names)
      ProjectConfigRepository.new(pd).new_project("project1")
      assert_equal(["project1"], pd.project_names)
      ProjectConfigRepository.new(pd).new_project("project2")
      assert_equal(["project1", "project2"], ProjectDirectories.new(@basedir).project_names)
    end

  end
end