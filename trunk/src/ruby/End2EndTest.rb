$:<<'../../lib'

require 'test/unit'
require 'ftools'
require 'fileutils'
require 'damagecontrol/Build'
require 'damagecontrol/SocketTrigger'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/Hub'
require 'damagecontrol/FileUtils'
require 'damagecontrol/scm/SCM'

require 'damagecontrol/Logging'

require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/template/ShortTextTemplate'

include DamageControl

# turn off debug logging
Logging.quiet

class IRCListener < IRCConnection
  attr_reader :received_text
  
  def initialize
    super
    reset_log
  end

  def on_recv_cmnd_privmsg(msg)
    @received_text += msg.args[0]
  end
  
  def reset_log
    @received_text = ""
  end
end

class End2EndTest < Test::Unit::TestCase

  def test_builds_on_cvs_add
    start_damagecontrol
    
    create_cvs_repository
    create_cvsmodule("e2eproject")
    
    install_damagecontrol_into_cvs(execute_script_commandline("build"))
    
    start_logging_irc_channel
    
    create_build_script_add_and_commit
    
    wait_less_time_than_default_quiet_period
    assert_not_built_yet
    
    wait_for_build_to_complete
    assert_build_produced_correct_output
    assert_build_successful_on_irc_channel
    assert_log_output_written_out
    
    reset_irc_log
    
    change_build_script_to_failing_and_commit
    wait_for_build_to_complete
    assert_build_failed_and_changes_on_irc_channel

    irc_listener.send_message_to_channel("Test successful. Thank you for your cooperation.")
  end
  
  attr_reader :irc_listener
  
  def start_logging_irc_channel
    @irc_listener = IRCListener.new
    irc_listener.connect("irc.codehaus.org", "testsuite")
    sleep 10
    assert(irc_listener.connected?)
    irc_listener.join_channel("#dce2e")
    puts "joined"
    sleep 1
    assert(irc_listener.in_channel?)
    irc_listener.send_message_to_channel("Hello, this is DamageControl's test-suite. I'm just here to check that DamageControl is performing its duties well.")
    sleep 1
    irc_listener.send_message_to_channel("I expect DamageControl to pop by soon and notify me of the build status, please ignore this.")
    sleep 1
  end
  
  def assert_log_output_written_out
    assert_equal(1, Dir["#{logdir}/e2eproject/*.log"].size)
  end
  
  def reset_irc_log
    irc_listener.reset_log
  end
  
  def assert_build_successful_on_irc_channel
    assert_match(/e2eproject/, irc_listener.received_text)
    assert_match(/BUILD SUCCESSFUL/, irc_listener.received_text)
  end
  
  def assert_build_failed_and_changes_on_irc_channel
    assert_match(/e2eproject/, irc_listener.received_text)
    assert_match(/BUILD FAILED/, irc_listener.received_text)
    assert_match(/#{username}/, irc_listener.received_text)
    irc_listener.send_message_to_channel("Test successful. Thank you for your cooperation.")
  end
  
  def change_build_script_to_failing_and_commit
    create_file("#{basedir}/e2eproject/#{script_file('build')}", 'this_will_not_work')
    commit("e2eproject")
  end
  
  def create_build_script_add_and_commit
    # add build.bat file and commit it (will trigger build)
    checkout_cvs_project("e2eproject")
    create_file("#{basedir}/e2eproject/#{script_file('build')}", 'echo "Hello world from DamageControl" > buildresult.txt')
    add_file_to_cvs_project("e2eproject", script_file("build"))
    commit("e2eproject")
  end
  
  include DamageControl::FileUtils
  
  attr_accessor :basedir
  
  def setup
    # Should be in setup, but we can't run DamageControl twice (it doesn't
    # shut down cleanly and can't rebind the port). If we change the temp
    # dir, all our builds will happen in the old one and the second (SVN)
    # test will fail.
    @basedir = "#{damagecontrol_home}/target/temp_e2e_#{Time.new.to_i}"
    File.mkpath(basedir)
    
    Dir.chdir(basedir)
    
    @cvsrootdir = "#{basedir}/repository"
    @cvsroot = ":local:#{@cvsrootdir}"
    @project = "e2eproject"
    
    @svn_repo_dir = "#{basedir}/repo";
    @svn_hooks_dir = "#{@svn_repo_dir}/hooks";
    @svn_url = "file:///#{@svn_repo_dir}";
    @svn_wc_checkout_dir = "#{basedir}/wc";
    @svn_wc_usage_dir = "#{@svn_wc_checkout_dir}/repo"
  end
  
  def Xteardown
    FileUtils.rm_rf("#{basedir}/#{@project}")
    FileUtils.rm_rf("#{basedir}/#{@cvsrootdir}")
    FileUtils.rm_rf("#{basedir}/#{@svn_repo_dir}")
  end

  def create_cvs_repository
    system("cvs -d#{@cvsroot} init")
  end
    
  def builddir
    "#{basedir}/build"
  end
  
  def logdir
    "#{basedir}/log"
  end
  
  def start_damagecontrol
    start_damagecontrol_forked
  end
        
  def start_damagecontrol_forked
    Thread.new {
      system("ruby #{damagecontrol_home}/src/ruby/start_damagecontrol_forked.rb #{basedir}")
    }
  end
  
  def with_working_dir(dir)
    prev = Dir.pwd
    begin
      Dir.chdir(dir)
      yield
    ensure
      Dir.chdir(prev)
    end
  end
  
  def create_cvsmodule(project)
    File.mkpath("#{basedir}/#{@project}")
    with_working_dir("#{basedir}/#{@project}") do
      system("cvs -d#{@cvsroot} import -m 'message' #{project} VENDOR START")
    end
  end
  
  def install_damagecontrol_into_cvs(build_command_line)
    cvs = CVS.new
    cvs.install_trigger(
          "#{basedir}/install_trigger_cvs_tmp",
          @project,
          "#{@cvsroot}:#{@project}",
          build_command_line,
          "e2eproject-dev@codehaus.org",
          "localhost",
          "14711",
          nc_exe_location)
  end
  
  def checkout_cvs_project(project)
    FileUtils.rm_rf("#{basedir}/#{project}")
    with_working_dir(basedir) do    
      system("cvs -d#{@cvsroot} co #{project}")
    end
    assert(File.exists?("#{basedir}/#{project}"))
  end
  
  def add_file_to_cvs_project(project, file)
    File.mkpath("#{basedir}/#{project}")
    with_working_dir("#{basedir}/#{project}") do
      system("cvs add #{file}")
    end
  end
  
  def commit(project)
    with_working_dir("#{basedir}/#{project}") do
      system("cvs com -m \"comment\"")
    end
  end
  
  def username
    return ENV["USERNAME"] if windows?
    ENV["USER"]
  end
  
  def script_file(file)
    return "#{file}.bat" if windows?
    "#{file}.sh"
  end

  def nc_file
    return "nc.exe" if windows?
    "nc"
  end
  
  def nc_exe_location
    return "#{damagecontrol_home}/bin/#{nc_file}" if windows?
    nil
  end
  
  def assert_file_content(expected_content, file, message)
    assert(FileTest::exists?(file), "#{file} doesn't exist, #{message}")
    File.open(file) do |io|
      assert_equal(expected_content, io.gets.chomp,
        "#{file} content wrong, #{message}")
    end
  end
  
  def delete_checked_out_project(project)
    FileUtils.rm_rf("#{basedir}/#{project}")
  end

  def wait_less_time_than_default_quiet_period
    sleep BuildScheduler::DEFAULT_QUIET_PERIOD - 1
  end

  def wait_for_build_to_complete
    sleep 30
  end

  def verify_output_of_svn_build
    assert_file_content('"Hello world from DamageControl" ', 
      "#{builddir}/repo/buildresult.txt", 
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
  
  def build_result
    "#{builddir}/e2eproject/buildresult.txt"
  end
  
  def assert_not_built_yet
    assert(!File.exists?(build_result), "build executed before quiet period elapsed")
  end
  
  def assert_build_produced_correct_output
    expected_content =
            if windows?
              '"Hello world from DamageControl" '
            else
              'Hello world from DamageControl'
            end
    assert_file_content(expected_content,
      build_result,
      "build not executed")
  end
  
  def TODO_test_builds_on_svn_add
      create_svn_repository
      start_damagecontrol
      install_and_activate_damagecontrol_for_svn
      checkout_svn_repository
      with_working_dir(@svn_wc_usage_dir) do
        File.open("build.bat", "w") do |file|
            file.puts('echo "Hello world from DamageControl" > buildresult.txt')
        end
        add_file_to_svn("build.bat")
      end
      
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
    with_working_dir(@svn_wc_checkout_dir) do
      system("svn checkout #{@svn_url}")
    end
  end
        
  def add_file_to_svn(filename)
    system("svn add #{filename}")
    system("svn commit -m \"Adding test file to svn\" #{filename}")
  end
end
