require 'test/unit'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/scm/SCMFactory'

module DamageControl

  class ProjectConfigRepositoryTest < Test::Unit::TestCase
    include FileUtils
  
    attr_reader :pcr
    attr_reader :basedir
    
    def setup
      @basedir = new_temp_dir
      @pcr = ProjectConfigRepository.new(ProjectDirectories.new(basedir), SCMFactory.new, "http://localhost/public")
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
      assert_equal({"project_name" => "newproject"}, @pcr.project_config("newproject"))
    end
    
    def test_can_modify_project_config
      @pcr.new_project("newproject")
      @pcr.modify_project_config("newproject", { "scm_spec" => ":local:/cvsroot" })
      assert_equal({"project_name" => "newproject", "scm_spec" => ":local:/cvsroot"}, 
        @pcr.project_config("newproject"))
    end

    def test_can_create_build_from_project_config
      timestamp = Build.format_timestamp(Time.utc(2004, 06, 15, 12, 00, 00))
      @pcr.new_project("newproject")
      @pcr.modify_project_config("newproject", { "scm_spec" => ":local:/cvsroot" })
      build = @pcr.create_build("newproject", timestamp)
      assert_equal(timestamp, build.timestamp)
      assert_equal({"project_name" => "newproject", "scm_spec" => ":local:/cvsroot"}, build.config)
      assert_equal("http://localhost/public/project?action=build_details&project_name=newproject&timestamp=20040615120000", build.url)
    end
    
    def test_next_build_number
      @pcr.new_project("newproject")
      assert_equal(1, @pcr.next_build_number("newproject"))
      assert_equal(2, @pcr.peek_next_build_number("newproject"))
      assert(File.exists?("#{basedir}/newproject/next_build_number"))
      assert("2", File.read("#{basedir}/newproject/next_build_number"))
      assert_equal(2, @pcr.next_build_number("newproject"))
      assert_equal(3, @pcr.next_build_number("newproject"))
      assert_equal(4, @pcr.next_build_number("newproject"))
      assert("5", File.read("#{basedir}/newproject/next_build_number"))
    end
  end
  
end