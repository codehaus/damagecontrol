require 'test/unit'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class ProjectDirectoriesTest < Test::Unit::TestCase
  
    include FileUtils
  
    def setup
      @basedir = new_temp_dir
      @pd = ProjectDirectories.new(@basedir)
    end
    
    def teardown
      rm_rf(@basedir)
    end

    def test_can_list_project_directories
      assert_equal([], @pd.project_names)
      ProjectConfigRepository.new(@pd, "").new_project("project1")
      assert_equal(["project1"], @pd.project_names)
      ProjectConfigRepository.new(@pd, "").new_project("project2")
      assert_equal(["project1", "project2"], ProjectDirectories.new(@basedir).project_names)
    end
    
    def test_can_access_logfile
      assert_equal(File.expand_path("#{@basedir}/project1/log/20040630155420.log"), 
        File.expand_path(@pd.log_file("project1", "20040630155420")))
    end

  end
end