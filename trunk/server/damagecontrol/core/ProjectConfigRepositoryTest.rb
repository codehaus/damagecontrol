require 'test/unit'
require 'damagecontrol/core/ProjectConfigRepository'

module DamageControl

  class ProjectConfigRepositoryTest < Test::Unit::TestCase
    include FileUtils
  
    attr_reader :pcr
    attr_reader :basedir
    
    def test_can_add_new_project
      @basedir = new_temp_dir("test_can_add_new_project")
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir))

      @pcr.new_project("newproject")
      assert(File.exists?("#{basedir}/newproject"))
      assert(File.exists?("#{basedir}/newproject/conf.yaml"))
    end
    
    def test_fails_if_project_already_exists
      @basedir = new_temp_dir("test_fails_if_project_already_exists")
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir))

      @pcr.new_project("newproject")
      assert_raises(ProjectAlreadyExistsError) do
        @pcr.new_project("newproject")
      end
    end
    
    def test_can_get_config_from_created_project
      @basedir = new_temp_dir("test_can_get_config_from_created_project")
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir))

      @pcr.new_project("newproject")
      assert(@pcr.project_exists?("newproject"))
      assert_equal({"project_name" => "newproject"}, @pcr.project_config("newproject"))
    end
    
    def test_can_modify_project_config
      @basedir = new_temp_dir("test_can_modify_project_config")
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir))

      @pcr.new_project("newproject")
      @pcr.modify_project_config("newproject", { "scm_spec" => ":local:/cvsroot" })
      assert_equal({"project_name" => "newproject", "scm_spec" => ":local:/cvsroot"}, 
        @pcr.project_config("newproject"))
    end

    def test_can_create_build_from_project_config
      @basedir = new_temp_dir("test_can_create_build_from_project_config")
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir))

      timestamp = Build.format_timestamp(Time.utc(2004, 06, 15, 12, 00, 00))
      @pcr.new_project("newproject")
      @pcr.modify_project_config("newproject", { "scm_spec" => ":local:/cvsroot" })
      build = @pcr.create_build("newproject", timestamp)
      assert_equal(timestamp, build.timestamp)
      assert_equal({"project_name" => "newproject", "scm_spec" => ":local:/cvsroot"}, build.config)
    end
  end
  
end