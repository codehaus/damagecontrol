require 'test/unit'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/scm/NoSCM'

module DamageControl

  class ProjectConfigRepositoryTest < Test::Unit::TestCase
    include FileUtils
  
    attr_reader :pcr
    attr_reader :basedir
    
    def setup
      @basedir = new_temp_dir
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir), "http://localhost/public")
    end
    
    def test_can_add_new_project
      @pcr.new_project("newproject")
      assert(File.exists?("#{basedir}/newproject"))
      assert(File.exists?("#{basedir}/newproject/conf.yaml"))
    end
    
    def test_fails_if_project_already_exists
      @pcr.new_project("newproject")
      assert_raises(ProjectAlreadyExistsError) do
        @pcr.new_project("newproject")
      end
    end
    
    def test_can_get_config_from_created_project
      @pcr.new_project("newproject")
      assert(@pcr.project_exists?("newproject"))
      assert_equal(
        {
          "project_name" => "newproject",
          "scm" => create_default_scm
        },
        @pcr.project_config("newproject"))
    end
    
    def test_can_modify_project_config
      @pcr.new_project("newproject")
      @pcr.modify_project_config("newproject", { "scm_type" => NoSCM.name })
      assert_equal(
        {
          "project_name" => "newproject",
          "scm" => create_default_scm
        },
        @pcr.project_config("newproject"))
    end
    
    def create_default_scm
      NoSCM.new
    end

    def test_can_create_build_from_project_config
      @pcr.new_project("newproject")
      @pcr.modify_project_config("newproject", { "scm_type" => NoSCM.name })
      build = @pcr.create_build("newproject")
      assert_equal(
        {
          "project_name" => "newproject",
          "scm" => create_default_scm
        },
        build.config)
      assert_match(/http:\/\/localhost\/public\/project\?project_name=newproject&timestamp=2\d\d\d\d\d\d\d\d\d\d\d\d\d/, build.url)
    end
    
    def test_next_build_number
      @pcr.new_project("newproject")
      assert_equal(1, @pcr.next_build_number("newproject"))
      assert_equal(2, @pcr.peek_next_build_number("newproject"))
      assert_equal(2, @pcr.next_build_number("newproject"))
      assert_equal(3, @pcr.next_build_number("newproject"))
      assert_equal(4, @pcr.next_build_number("newproject"))
    end
  end
  
end