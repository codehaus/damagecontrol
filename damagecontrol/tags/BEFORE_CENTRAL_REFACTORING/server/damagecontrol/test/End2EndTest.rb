require 'test/unit'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/SocketTrigger'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/Hub'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/SCM'

require 'damagecontrol/util/Logging'

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
    sleep 3
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
  
  def wait_for(timeout=60, &proc)
    0.upto(timeout) do
      return if proc.call
      sleep 1
    end
  end
  
  def wait_for_output(output, timeout=60)
    wait_for do
      irc_listener.received_text =~ /#{output}/
    end
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

class Driver
  attr_reader :basedir

  include Test::Unit::Assertions
  include FileUtils

  def initialize(basedir)
    @basedir = basedir
  end
  
  def setup
  end

  def teardown
    #FileUtils.rm_rf(cvsrootdir)
  end
  
  def system(cmd)
    puts "system(#{cmd})"
    result = super(cmd)
    assert($? == 0, "#{cmd} failed with code #{$?.to_s}")
    result
  end
  
end

class CVSDriver < Driver

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

class SVNDriver < Driver

  def setup
    @svn_wc_checkout_dir = "#{basedir}/wc"
    @svn_wc_usage_dir = "#{@svn_wc_checkout_dir}/repo"
  end
  
  def create_repository
    system("svnadmin create #{repositorydir}")
  end
  
  def create_module(project)
  end
  
  def TODO_test_builds_on_svn_add
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
        
  def install_damagecontrol(project, build_commandline)
    # install hook
    File.open("#{hooksdir}/#{script_file('post-commit')}", "w") do |file|
      file.puts("@echo off")
      file.puts("")
      file.puts("REM Autogenerated script to call DamageControl when a commit succeeds")
      file.puts("")
      conf_file = conf_script(url, BuildBootstrapper.conf_file(project_name))
      trigger_command = BuildBootstrapper.trigger_command(project_name, conf_file, nc_command(url), dc_host, dc_port)
      file.puts(trigger_command)
    end
    # install conf file
    File.open(BuildBootstrapper.conf_file(project_name), "w") do |file|
      build_spec = BuildBootstrapper.build_spec(project_name, scm_spec, build_command_line, nag_email)
      file.puts(build_spec)
    end
    system("chmod +x #{hooksdir}/#{script_file('post-commit')}") unless windows?
    File.copy(nc_exe_location, "#{hooksdir}/#{nc_file}" ) if windows?
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
  
  def hooksdir
    "#{repositorydir}/hooks"
  end
  
  def repositorydir
    "#{basedir}/repo"
  end

  def url
    "file:///#{repositorydir}"
  end

end

class DamageControlServerDriver < Driver
  include Test::Unit::Assertions
  
  def setup
    @server_startup_result = true
    start_damagecontrol_forked
  end
  
  def timeout
    120
  end
  
  def startup_script
    "#{damagecontrol_home}/server/damagecontrol/test/E2EStartServerForked.rb"
  end
  
  def start_damagecontrol_forked
    Thread.new {
      @server_startup_result = system("ruby -I#{damagecontrol_home}/server #{startup_script} #{basedir} #{timeout}")
    }
  end
  
  def teardown
    assert(@server_startup_result, "server did not start up properly")
  end
end

class End2EndTest < Test::Unit::TestCase

  include FileUtils
  
  attr_reader :basedir
  attr_reader :irc
  attr_reader :cvs
  attr_reader :svn
  attr_reader :scm
  
  def setup
    @basedir = "#{damagecontrol_home}/target/temp_e2e_#{Time.new.to_i}"
    File.mkpath(basedir)
    
    @server = DamageControlServerDriver.new(basedir)
    @server.setup
    
    @irc = IRCDriver.new
    irc.setup
  end
  
  def teardown
    irc.teardown
    scm.teardown unless scm.nil?
    @server.teardown
    
    #FileUtils.rm_rf(basedir)
  end
  
  def test_damagecontrol_works_with_cvs
    test_build_and_log_and_irc(CVSDriver)
  end
  
  def TODO_test_damagecontrol_works_with_svn
    test_build_and_log_and_irc(SVNDriver)
  end
  
  def test_build_and_log_and_irc(scm_driver)
    @scm = scm_driver.new(basedir)  
    scm.setup
    
    scm.create_repository
    scm.create_module(project)
    
    scm.install_damagecontrol(project, execute_script_commandline("build"))
    
    create_build_script_add_and_commit
    
    wait_less_time_than_default_quiet_period
    assert_not_built_yet
    
    wait_for_build_to_succeed
    assert_build_produced_correct_output
    irc.assert_build_successful_on_channel(project)
    assert_log_output_written_out
    
    irc.reset_log
    
    change_build_script_to_failing_and_commit
    wait_for_build_to_fail
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
  
  def builddir
    "#{basedir}/build"
  end
  
  def logdir
    "#{basedir}/log"
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

  def wait_for_build_to_succeed
    irc.wait_for_output("BUILD SUCCESSFUL")
  end

  def wait_for_build_to_fail
    irc.wait_for_output("BUILD FAILED")
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
    "#{basedir}/checkout/#{project}/buildresult.txt"
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