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

class IRCDriver

  include Test::Unit::Assertions

  attr_reader :irc_listener

  def setup
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

  def reset_log
    irc_listener.reset_log
  end
  
  def teardown
    irc_listener.send_message_to_channel("Test successful. Thank you for your cooperation.")
  end
  
  def assert_build_successful_on_channel(project)
    assert_match(/e2eproject/, irc_listener.received_text)
    assert_match(/BUILD SUCCESSFUL/, irc_listener.received_text)
  end
  
  def assert_build_failed_and_changes_on_channel(project, username)
    assert_match(/e2eproject/, irc_listener.received_text)
    assert_match(/BUILD FAILED/, irc_listener.received_text)
    assert_match(/#{username}/, irc_listener.received_text)
  end

end

class SCMDriver
  attr_reader :basedir

  include Test::Unit::Assertions
  include DamageControl::FileUtils

  def initialize(basedir)
    @basedir = basedir
  end
  
  def setup
  end

  def teardown
    #FileUtils.rm_rf(cvsrootdir)
  end
  
  def system(cmd)
    super(cmd)
    assert($? == 0, "#{cmd} failed with code #{$?.to_s}")
  end
  
end

class CVSDriver < SCMDriver

  def create_repository
    system("cvs -d#{cvsroot} init")
  end

  def create_module(name)
    File.mkpath("#{basedir}/#{name}")
    with_working_dir("#{basedir}/#{name}") do
      system("cvs -d#{cvsroot} import -m 'message' #{name} VENDOR START")
    end
  end

  def install_damagecontrol(project, build_command_line)
    cvs = CVS.new
    cvs.install_trigger(
          "#{basedir}/install_trigger_cvs_tmp",
          project,
          "#{cvsroot}:#{project}",
          build_command_line,
          "#{project}-dev@codehaus.org",
          "localhost",
          "14711",
          nc_exe_location)
  end
  
  def checkoutdir(project)
    "#{basedir}/#{project}"
  end
  
  def checkout(project)
    FileUtils.rm_rf(checkoutdir(project))
    with_working_dir("#{checkoutdir(project)}/..") do    
      system("cvs -d#{cvsroot} co #{project}")
    end
    assert(File.exists?(checkoutdir(project)))
  end
  
  def add_file(project, file)
    File.mkpath(checkoutdir(project))
    with_working_dir(checkoutdir(project)) do
      system("cvs add #{file}")
    end
  end
  
  def commit(project)
    with_working_dir(checkoutdir(project)) do
      system("cvs com -m \"comment\"")
    end
  end
  
  def cvsroot
    ":local:#{cvsrootdir}"
  end
  
  private
  
  def exe_file(name)
    return "#{name}.exe" if windows?
    name
  end
  
  def nc_exe_location
    return "#{damagecontrol_home}/bin/#{exe_file('nc')}" if windows?
    nil
  end
  
  def cvsrootdir
    "#{basedir}/repository"
  end
    
end

class SVNDriver < SCMDriver

  def setup
    @svn_repo_dir = "#{basedir}/repo"
    @svn_hooks_dir = "#{@svn_repo_dir}/hooks"
    @svn_url = "file:///#{@svn_repo_dir}"
    @svn_wc_checkout_dir = "#{basedir}/wc"
    @svn_wc_usage_dir = "#{@svn_wc_checkout_dir}/repo"
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

module Kernel
  alias_method :old_system, :system
  def system(*args)
    result = old_system(*args)
    puts "system(#{args.join(', ')}) returned #{result}"
    result
  end
end

class End2EndTest < Test::Unit::TestCase

  def setup
    @basedir = "#{damagecontrol_home}/target/temp_e2e_#{Time.new.to_i}"
    File.mkpath(basedir)
    
    Dir.chdir(basedir)
    
    @irc = IRCDriver.new
    irc.setup
    
    @scm = CVSDriver.new(basedir)
    scm.setup
  end
  
  def test_builds_on_cvs_add
    start_damagecontrol
    
    scm.create_repository
    scm.create_module(project)
    
    scm.install_damagecontrol(project, execute_script_commandline("build"))
    
    create_build_script_add_and_commit
    
    wait_less_time_than_default_quiet_period
    assert_not_built_yet
    
    wait_for_build_to_complete
    assert_build_produced_correct_output
    irc.assert_build_successful_on_channel(project)
    assert_log_output_written_out
    
    irc.reset_log
    
    change_build_script_to_failing_and_commit
    wait_for_build_to_complete
    irc.assert_build_failed_and_changes_on_channel(project, username)
  end
  
  def assert_log_output_written_out
    assert_equal(1, Dir["#{logdir}/e2eproject/*.log"].size)
  end
  
  def create_build_script_add_and_commit
    # add build.bat file and commit it (will trigger build)
    scm.checkout(project)
    create_file("#{checkoutdir}/#{script_file('build')}", 'echo "Hello world from DamageControl" > buildresult.txt')
    scm.add_file(project, script_file("build"))
    scm.commit(project)
  end
  
  def change_build_script_to_failing_and_commit
    create_file("#{checkoutdir}/#{script_file('build')}", 'this_will_not_work')
    scm.commit(project)
  end
  
  def checkoutdir
    scm.checkoutdir(project)
  end
  
  include DamageControl::FileUtils
  
  attr_reader :basedir
  attr_reader :irc
  attr_reader :scm
  
  def teardown
    irc.teardown
    scm.teardown
    #FileUtils.rm_rf(basedir)
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
  
  def cvsroot
    scm.cvsroot
  end
  
  def project
    "e2eproject"
  end
  
  def username
    return ENV["USERNAME"] if windows?
    ENV["USER"]
  end
  
  def script_file(file)
    return "#{file}.bat" if windows?
    "#{file}.sh"
  end

  def assert_file_content(expected_content, file, message)
    assert(FileTest::exists?(file), "#{file} doesn't exist, #{message}")
    File.open(file) do |io|
      assert_equal(expected_content, io.gets.chomp,
        "#{file} content wrong, #{message}")
    end
  end
  
  def wait_less_time_than_default_quiet_period
    sleep BuildScheduler::DEFAULT_QUIET_PERIOD - 1
  end

  def wait_for_build_to_complete
    sleep 30
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
    "#{basedir}/build/#{project}/buildresult.txt"
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
end
