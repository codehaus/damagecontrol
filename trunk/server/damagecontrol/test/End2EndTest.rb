require 'test/unit'

require 'xmlrpc/client'

require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/ProjectConfigRepository'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/xmlrpc/ConnectionTester'
require 'damagecontrol/util/Logging'
require 'damagecontrol/publisher/IRCPublisher'

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
    irc_listener.send_message_to_channel("Test ended. Thank you for your cooperation.")
  end
  
  def wait_for_output(output, timeout=60)
    wait_for do
      irc_listener.received_text =~ /#{output}/
    end
  end
  
  def assert_build_successful_on_channel
    assert_match(/\[TestingProject\] BUILD SUCCESSFUL/, irc_listener.received_text)
  end
  
  def assert_build_failed_and_changes_on_channel(username)
    assert_match(/\[TestingProject\] BUILD FAILED/, irc_listener.received_text)
    assert_match(/#{username}/, irc_listener.received_text)
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
    #FileUtils.rm_rf(cvsrootdir)
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
      @server_startup_result = system("ruby -I#{damagecontrol_home}/server #{startup_script} #{basedir} #{timeout}")
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
  
  def setup_project_config(project, scm, build_command_line)
    new_project(project)
    
    pd = ProjectDirectories.new(basedir)
    project_config_repo = ProjectConfigRepository.new(pd)
    project_config = project_config_repo.project_config(project)

    project_config["build_command_line"] = build_command_line
    # TODO: we need a general way to ask the scm for this stuff.
    # Perhaps a method on each SCM called config_map
    project_config["scm_type"] = "cvs"
    project_config["cvsroot"] = scm.cvsroot
    project_config["cvsmodule"] = scm.mod
    
    project_config_repo.modify_project_config(project, project_config)
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
    puts @server_startup_result
    assert(!server_shutdown?, "server did not start up properly")
    shutdown_server
    wait_for(20) { server_shutdown? }
    assert(server_shutdown?, "server did not shut down")
    assert(@server_startup_result, "server did not start up/shut down cleanly")
  end
end

# Extension that allows local repo creation and import of files.
# (This is not needed in the superclass, since it is not used by DC)
class LocalCVS < CVS
  def initialize(cvsrootdir, mod, working_dir_root)
    super(":local:#{cvsrootdir}", mod, working_dir_root)
    @cvsrootdir = cvsrootdir
  end
  
  def create
    File.mkpath(@cvsrootdir)
    cvs("-d#{cvsroot} init")
  end
  
  def import(dir)
    with_working_dir(dir) do
      modulename = File.basename(dir)
      cvs("-d#{cvsroot} import -m \"initial import\" #{modulename} VENDOR START")
    end    
  end
  
  def add_file(relative_filename, content, is_new)
    with_working_dir(working_dir) do
      File.mkpath(File.dirname(relative_filename))
      File.open(relative_filename, "w") do |file|
        file.puts(content)
      end
      
      if(is_new)
        cvs("add #{relative_filename}")
      end

      cvs("com -m \"adding #{relative_filename}\"")
    end
  end
end

class End2EndTest < Test::Unit::TestCase

  include FileUtils
  
  attr_reader :basedir
  attr_reader :irc
  attr_reader :cvs
  attr_reader :svn
  attr_reader :scm
  attr_reader :server
  
  def setup
    @basedir = new_temp_dir("e2e")
    File.mkpath(basedir)
  end
  
  def teardown
    server.teardown
    irc.teardown
    scm.teardown unless scm.nil?
    
    #FileUtils.rm_rf(basedir)
  end
  
  def test_damagecontrol_works_with_cvs
    cvsrootdir = "#{@basedir}/cvsroot"
    mod = "testproject"
    working_dir_root = "#{@basedir}/userwork"
    cvs = LocalCVS.new(cvsrootdir, mod, working_dir_root)
    
    test_build_and_log_and_irc(cvs)
  end
  
  def TODO_test_damagecontrol_works_with_svn
    svn = LocalSVN.new()
    test_build_and_log_and_irc(svn)
  end
  
  def test_build_and_log_and_irc(scm)
    # prepare local scm
    scm.create
    importdir = "#{@basedir}/testproject"
    File.mkpath(importdir)
    scm.import(importdir)
    scm.install_trigger("TestingProject", "http://localhost:14712/private/xmlrpc")

    @server = DamageControlServerDriver.new("#{basedir}/serverroot")
    server.setup    
    @irc = IRCDriver.new
    irc.setup

    server.setup_project_config("TestingProject", scm, execute_script_commandline("build"))
    
    # add build.bat file and commit it (will trigger build)
    scm.checkout
    scm.add_file(script_file("build"), 'echo "Hello world from DamageControl" > buildresult.txt', true)
    
    wait_less_time_than_default_quiet_period
    assert_not_built_yet
    
    wait_for_build_to_succeed
    assert_build_produced_correct_output
    irc.assert_build_successful_on_channel
    assert_log_output_written_out
    
    irc.reset_log
    
    # update the buld file to something bogus, which should fail the build
    scm.add_file(script_file("build"), 'this_will_not_work', false)

    wait_for_build_to_fail
    irc.assert_build_failed_and_changes_on_channel(username)
  end
  
  def assert_log_output_written_out
    assert_equal(1, Dir["#{basedir}/serverroot/TestingProject/log/*.log"].size)
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

  def execute_script_commandline(name)
    if windows?
      script_file("build")
    else
      "sh #{script_file(name)}"
    end
  end
  
  def build_result
    "#{basedir}/serverroot/TestingProject/checkout/testproject/buildresult.txt"
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
    assert_file_content(expected_content, build_result, "build not executed")
  end
end

end