require 'test/unit'
require 'ftools'
require 'damagecontrol/Build'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/Hub'
require 'damagecontrol/FileUtils'
require 'damagecontrol/scm/SCM'

include DamageControl

class End2EndTest < Test::Unit::TestCase
	
	include FileUtils
        
  def initialize(someparam)
      super(someparam)
      @@damagecontrol_started = false
  
      # Should be in setup, but we can't run DamageControl twice (it doesn't
      # shut down cleanly and can't rebind the port). If we change the temp
      # dir, all our builds will happen in the old one and the second (SVN)
      # test will fail.
      @basedir = damagecontrol_home
      @tempdir = "#{@basedir}/target/temp_e2e_#{Time.new.to_i}"
      File.mkpath(@tempdir)
  end
        
  def setup
    Dir.chdir(@tempdir)
    
    @cvsrootdir = "#{@tempdir}/repository"
    @cvsroot = ":local:#{@cvsrootdir}"
    @project = "e2eproject"
    
    @svn_repo_dir = "#{@tempdir}/repo";
    @svn_hooks_dir = "#{@svn_repo_dir}/hooks";
    @svn_url = "file:///#{@svn_repo_dir}";
    @svn_wc_checkout_dir = "#{@tempdir}/wc";
    @svn_wc_usage_dir = "#{@svn_wc_checkout_dir}/repo"
  end
	
  def Xteardown
    Dir.chdir(@tempdir)
    rmdir(@project)
    rmdir(@cvsrootdir)
    rmdir(@svn_repo_dir)
  end

  def create_cvs_repository()
    system("cvs -d#{@cvsroot} init")
  end
		
  class SysOutProgressReporter
    def initialize(hub)
      hub.add_subscriber(self)
    end
    
    def receive_message(message)
      if !message.is_a?(BuildEvent)
        return
      end
      
      name = message.build.project_name
      if message.is_a?(BuildRequestEvent)
        puts "[#{name}] BUILD STARTING"
      end
      
      if message.is_a?(BuildProgressEvent)
        puts "[#{name}] [#{message.build.project_name}] #{message.output}"
      end
      
      if message.is_a?(BuildCompleteEvent)
        puts "BUILD COMPLETE [#{message.build.project_name}]"
      end
    end
  end
  
  def buildsdir
    "#{@tempdir}/builds"
  end
	
  def start_damagecontrol
    if(@@damagecontrol_started == false) then
      $:<<"#{damagecontrol_home}/src/ruby"
      require 'simple'
      start_simple_server(buildsdir, 4713)
      @@damagecontrol_started = true
    end
  end
        
	
  def create_cvsmodule(project)
    Dir.chdir(@tempdir)
    File.mkpath(@project)
    Dir.chdir(@project)
    system("cvs -d#{@cvsroot} import -m 'message' #{project} VENDOR START")
  end
	
  def install_damagecontrol_into_cvs(build_command_line)
    cvs = CVS.new
    cvs.install_trigger(
                        "#{@tempdir}/install_trigger_cvs_tmp",
          @project,
                        "#{@cvsroot}:#{@project}",
          build_command_line,
                        "e2eproject-dev@codehaus.org",
                        "localhost",
                        "4713",
                        nc_exe_location)
  end
	
  def checkout_cvs_project(project)
    Dir.chdir(@tempdir)
    rmdir(project)
    system("cvs -d#{@cvsroot} co #{project}")
  end
	
  def add_file_to_cvs_project(project, file)
    Dir.chdir("#{@tempdir}/#{project}")
    system("cvs add #{file}")
    system("cvs com -m 'comment'")
  end
	
  def script_file(file)
    if windows?
      "#{file}.bat"
    else
      "#{file}.sh"
    end
  end

  def nc_file
    if windows?
      "nc.exe"
    else
      "nc"
    end
  end
  
  def nc_exe_location
    if windows?
      "#{@basedir}/bin/#{nc_file}"
    else
      nil
    end
  end
	
	def assert_file_content(expected_content, file, message)
		assert(FileTest::exists?(file), "#{file} doesn't exist, #{message}")
		File.open(file) do |io|
			assert_equal(expected_content, io.gets.chomp,
				"#{file} content wrong, #{message}")
		end
	end
	
	def delete_checked_out_project(project)
		Dir.chdir(@tempdir)
		rmdir(project)
	end

  def wait_for_build_to_complete
    sleep 5
  end

  def verify_output_of_svn_build
		assert_file_content('"Hello world from DamageControl" ', 
			"#{buildsdir}/repo/buildresult.txt", 
			"build not executed")
  end
  
  def create_file(name, content)
		File.open(name, "w") do |file|
			file.puts(content)
		end
  end

  def execute_script_commandline(name)
    if windows?
      script_file("build")
    else
      "sh #{script_file(name)}"
    end
  end
  
  def test_builds_on_cvs_add
    create_cvs_repository
    create_cvsmodule("e2eproject")
    install_damagecontrol_into_cvs(execute_script_commandline("build"))
    
    start_damagecontrol
    
    # add build.bat file and commit it (will trigger build)
    checkout_cvs_project("e2eproject")
    create_file("e2eproject/#{script_file('build')}", 'echo "Hello world from DamageControl" > buildresult.txt')
    add_file_to_cvs_project("e2eproject", script_file("build"))
    
    wait_for_build_to_complete
    expected_content =
            if windows?
              '"Hello world from DamageControl" '
            else
              'Hello world from DamageControl'
            end
    assert_file_content(expected_content,
			"#{buildsdir}/e2eproject/buildresult.txt", 
			"build not executed")
  end
  
  def TODO_test_builds_on_svn_add
      create_svn_repository
      start_damagecontrol
      install_and_activate_damagecontrol_for_svn
      checkout_svn_repository
      Dir.chdir(@svn_wc_usage_dir)
      File.open("build.bat", "w") do |file|
          file.puts('echo "Hello world from DamageControl" > buildresult.txt')
      end
      add_file_to_svn("build.bat")
      
      wait_for_build_to_complete
      verify_output_of_svn_build
  end
        
  def create_svn_repository
    dsystem("svnadmin create #{@svn_repo_dir}")
  end
        
  def install_and_activate_damagecontrol_for_svn
    File.open("#{@svn_hooks_dir}/post-commit.bat", "w") do |file|
      file.puts("@echo off")
      file.puts("")
      file.puts("REM Autogenerated script to call DamageControl when a commit succeeds")
      file.puts("REM %~dp0 is Windows syntax for the directory the current script")
      file.puts("REM lives in (don't ask...)")
      file.puts("")
      file.puts("%~dp0damagecontrol.bat repo #{@svn_url} #{script_file("build")}")
    end
    File.copy("#{trigger_script}", script_file("#{@svn_hooks_dir}/damagecontrol"))
    File.copy(nc_exe_location, "#{@svn_hooks_dir}/#{nc_file}" )
  end
        
  def checkout_svn_repository
    File.mkpath(@svn_wc_checkout_dir)
    Dir.chdir(@svn_wc_checkout_dir)
    dsystem("svn checkout #{@svn_url}")
  end
        
  def add_file_to_svn(filename)
    dsystem("svn add #{filename}")
    dsystem("svn commit -m \"Adding test file to svn\" #{filename}")
  end
        
  def dsystem(cmd)
    puts "current dir: " + Dir.pwd()
    puts "running command: #{cmd}"
    system cmd
  end
end
