# HEY! It's better to run a local IRC server (there is one called Join Me!) and do a
# export DC_TEST_IRC_HOST=localhost (see E2EStartServerForked.rb)
# Works like a charm. Aslak.
ONLINE=true

require 'test/unit'

require 'xmlrpc/client'
require 'pebbles/Pathutils'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/publisher/IRCPublisher'
require 'damagecontrol/scm/CVS'
require 'damagecontrol/scm/SVN'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/xmlrpc/ConnectionTester'
require 'damagecontrol/xmlrpc/Trigger'
require 'damagecontrol/util/Logging'

module DamageControl

# turn off debug logging
#Logging.quiet

module Utils
  def wait_for(timeout=60, &proc)
    0.upto(timeout) do
      return if proc.call
      sleep 1
    end
  end

  def baseurl
    "http://localhost:14712"
  end
  
  def privateurl
    "#{baseurl}/private/xmlrpc"
  end
  
  def publicurl
    "#{baseurl}/public/xmlrpc"
  end
  
end

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

  include Utils
  include Test::Unit::Assertions

  attr_reader :irc_listener

  def setup
    @irc_listener = IRCListener.new
    irc_host = ENV["DC_TEST_IRC_HOST"] || "irc.codehaus.org"
    irc_listener.connect(irc_host, "testsuite")
    wait_for(10) { irc_listener.connected? }
    assert("could not connect to irc", irc_listener.connected?)
    irc_listener.join_channel("#dce2e")
    wait_for(15) { irc_listener.in_channel? }
    assert("could not join irc channel", irc_listener.in_channel?)
    irc_listener.send_message_to_channel("Hello, this is DamageControl's test-suite. I'm just here to check that DamageControl is performing its duties well.")
    sleep 1
    irc_listener.send_message_to_channel("I expect DamageControl to pop by soon and notify me of the build status, please ignore this.")
    sleep 1
  end

  def reset_log
    irc_listener.reset_log
  end
  
  def teardown
    irc_listener.send_message_to_channel("Test ended. Thank you for your cooperation.")
  end
  
  def wait_for_successful_build
    wait_for_output("BUILD SUCCESSFUL")
  end

  def wait_for_failed_build  
    wait_for_output("BUILD FAILED")
  end
  
  def assert_build_successful_on_channel(project_name)
    assert_match(/\[#{project_name}\] BUILD SUCCESSFUL/, irc_listener.received_text)
  end
  
  def assert_build_failed_and_changes_on_channel(username, project_name)
    assert_match(/\[#{project_name}\] BUILD FAILED/, irc_listener.received_text)
    assert_match(/#{username}/, irc_listener.received_text)
  end

  private
  
  def wait_for_output(output, timeout=60)
    wait_for do
      irc_listener.received_text =~ /#{output}/
    end
  end
  
end

class OfflineIRCDriver
  def setup
  end
  
  def teardown
  end
  
  def wait_for_successful_build
  end
  
  def wait_for_failed_build  
  end
  
  def assert_build_successful_on_channel(project_name)
  end
  
  def assert_build_failed_and_changes_on_channel(username, project_name)
  end
  
  def reset_log
  end
end

class Driver
  attr_reader :basedir

  include Test::Unit::Assertions
  include FileUtils
  include Utils

  def initialize(basedir)
    @basedir = basedir
  end
  
  def setup
  end

  def teardown
  end
  
  def system(cmd)
    puts "system(#{cmd})"
    result = super(cmd)
    assert($? == 0, "#{cmd} failed with code #{$?.to_s}")
    result
  end
  
end

class DamageControlServerDriver < Driver
  include Utils
  include Test::Unit::Assertions
  
  def setup
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
      @server_startup_result = nil
      @server_startup_result = system("ruby -I#{damagecontrol_home}/server #{startup_script} #{basedir} #{timeout} #{ONLINE}")
    }
    wait_for(15) { server_running? }
    assert_server_running
  end
  
  def bindir
    "#{damagecontrol_home}/bin"
  end
  
  def new_project(project)
    system("ruby #{bindir}/newproject.rb --rootdir #{basedir} --projectname #{project}")
  end
  
  def setup_project_config(project, scm, build_command_line, polling)
    new_project(project)
    
    pd = ProjectDirectories.new(basedir)
    project_config_repo = ProjectConfigRepository.new(pd, "")
    project_config = project_config_repo.project_config(project)

    project_config["build_command_line"] = build_command_line
    project_config["scm"] = scm
    project_config["polling"] = true if polling
    
    project_config_repo.modify_project_config(project, project_config)
  end
  
  def assert_server_running
    assert(server_running?, "server did not start up properly")
  end
  
  def shutdown_server
    system("ruby #{bindir}/shutdownserver.rb --url #{privateurl}")
  end
  
  def server_running?
    begin
      client = ::XMLRPC::Client.new2(publicurl)
      control = client.proxy("test")
      control.ping == DamageControl::XMLRPC::ConnectionTester::PING_RESPONSE
    rescue Timeout::Error => e
      false
    rescue Errno::ECONNREFUSED => e
      false
    rescue Exception => e
      puts Logging.format_exception(e)
      false
    end
  end
  
  def server_shutdown?
    !@server_startup_result.nil?
  end
  
  def teardown
    assert_server_running
    assert(!server_shutdown?, "server did not start up properly")
    shutdown_server
    wait_for(20) { server_shutdown? }
    assert(server_shutdown?, "server did not shut down")
    assert(@server_startup_result, "server did not start up/shut down cleanly")
  end
end

class XMLRPCDriver < Driver
  def initialize(project_name, publicurl)
    @project_name = project_name
    client = ::XMLRPC::Client.new2(publicurl)
    @status = client.proxy("status")
  end
  
  def last_completed_build_status
    last_completed_build = @status.last_completed_build(@project_name)
    last_completed_build ? last_completed_build.status : "not completed"
  end
  
  def build_status?(status)
    begin
      last_completed_build_status == status
    rescue ::XMLRPC::FaultException => e
      flunk(e.faultString)
    end
  end
  
  def assert_build_successful
    assert(build_status?(Build::SUCCESSFUL), "build was not successful, it was #{last_completed_build_status}")
  end
  
  def assert_build_failed
    assert(build_status?(Build::FAILED), "build did not fail, it was #{last_completed_build_status}")
  end
  
  def wait_for_successful_build
    wait_for do
      build_status?(Build::SUCCESSFUL)
    end
    assert_build_successful
  end
  
  def wait_for_failed_build
    wait_for do
      build_status?(Build::FAILED)
    end
    assert_build_failed
  end
end

class End2EndTest < Test::Unit::TestCase

  include Pebbles::Pathutils
  include FileUtils
  include Utils
  
  attr_reader :basedir
  attr_reader :irc
  attr_reader :cvs
  attr_reader :svn
  attr_reader :scm
  attr_reader :server
  attr_reader :xmlrpc
  
  def teardown
    @server.teardown
    @irc.teardown if @irc
    @scm.teardown if @scm
    @xmlrpc.teardown if @xmlrpc
  end
  
  def setup
    @basedir                    = new_temp_dir("e2etest")
    @repo_dir                   = "#{@basedir}/repository"
    @relative_project_root      = "e2e"
    @relative_project_path      = "#{@relative_project_root}/testproject"
    @import_root_dir            = "#{@basedir}/#{@relative_project_root}"
    @import_base_dir            = "#{@basedir}/#{@relative_project_path}"
    @user_checkout_dir          = "#{@basedir}/user_checkout"
    @trigger_files_checkout_dir = "#{@basedir}/trigger_files_checkout"
    @server_work_dir            = "#{@basedir}/server_work"
    File.mkpath(basedir)
  end
  
  def testdummy
  end
  
  def Xtest_damagecontrol_works_with_cvs
    @project_name = "CVS_TestingProject"

    central_cvs = LocalCVS.new(@repo_dir, @relative_project_path)
    import_sources(central_cvs)

    remote_cvs = CVS.new
    rootdir = filepath_to_nativepath(@repo_dir, false)
    remote_cvs.cvsroot = ":local:#{rootdir}"
    remote_cvs.cvsmodule = "#{@relative_project_path}"

    test_build_and_log_and_irc(remote_cvs, false)
  end

  def Xtest_damagecontrol_works_with_svn
    @project_name = "SVN_TestingProject"

    central_svn = SVN.new
    central_svn.svnurl = filepath_to_nativeurl("#{@repo_dir}/#{@relative_project_path}")
    central_svn.svnpath = "#{@relative_project_path}"
    import_sources(central_svn)

    remote_svn = SVN.new
    remote_svn.svnurl = filepath_to_nativeurl("#{@repo_dir}/#{@relative_project_path}")
    remote_svn.svnpath = "#{@relative_project_path}"
    test_build_and_log_and_irc(remote_svn, true)
  end
  
  def import_sources(central_scm)
    central_scm.create
    mkdir_p(@import_base_dir)
    File.open("#{@import_base_dir}/dummy.txt", "w") {|file|
      file.puts "bla"
    }
    central_scm.import(@import_root_dir) { |line| puts line }
    
    trigger_command = DamageControl::XMLRPC::Trigger.trigger_command(damagecontrol_home, @project_name, privateurl)
    central_scm.install_trigger(trigger_command, @trigger_files_checkout_dir)
  end
  
  def test_build_and_log_and_irc(remote_scm, polling)

    @server = DamageControlServerDriver.new(@server_work_dir)
    @server.setup
    @irc = ONLINE ? IRCDriver.new : OfflineIRCDriver.new
    @irc.setup
    @xmlrpc = XMLRPCDriver.new(@project_name, @server.publicurl)

    server.setup_project_config(@project_name, remote_scm, execute_script_commandline("build"), polling)
    
    # add build.bat file and commit it (should trig build)
    remote_scm.checkout(@user_checkout_dir, nil, nil) { |line| puts line }

    remote_scm.add_or_edit_and_commit_file(@user_checkout_dir, script_file("build"), 'echo "Hello world from DamageControl" > buildresult.txt')

    wait_less_time_than_default_quiet_period
    assert_not_built_yet unless polling
    
    wait_for_build_to_succeed
    assert_build_produced_correct_output
    wait_for(10) do
      irc.assert_build_successful_on_channel(@project_name)
    end
    assert_log_output_written_out
    
    irc.reset_log
    
    # update the buld file to something bogus, which should fail the build
    remote_scm.add_or_edit_and_commit_file(@user_checkout_dir, script_file("build"), 'this_will_not_work')

    wait_for_build_to_fail
    irc.assert_build_failed_and_changes_on_channel(username, @project_name)
  end
  
  def assert_log_output_written_out
    assert(0 < Dir["#{@server_work_dir}/#{@project_name}/log/*.log"].size)
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
    irc.wait_for_successful_build
#    xmlrpc.wait_for_successful_build
  end

  def wait_for_build_to_fail
    irc.wait_for_failed_build
#    xmlrpc.wait_for_failed_build
  end

  def execute_script_commandline(name)
    "sh #{script_file(name)}"
  end
  
  def build_result
    "#{@server_work_dir}/#{@project_name}/checkout/buildresult.txt"
  end
  
  def assert_not_built_yet
    br = build_result
    assert(!File.exists?(br), "build executed before quiet period elapsed. Shouldn't exist yet: #{br}")
  end
  
  def assert_build_produced_correct_output
    expected_content = 'Hello world from DamageControl'
    assert_file_content(expected_content, build_result, "build not executed")
  end
end

end
