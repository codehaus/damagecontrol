require 'test/unit'

require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'
require 'damagecontrol/HubTestHelper'

require 'socket'

module DamageControl

  class SocketTriggerTest < Test::Unit::TestCase
    include FileUtils
    include HubTestHelper
    
    def setup
      create_hub
      @socket_trigger = SocketTrigger.new(hub)
      @project_name = "picocontainer"
      @socket_triggercm_spec = ":local:/cvsroot/picocontainer:pico"
      @build_command_line = "echo damagecontrol rocks"
      @nag_email = "damagecontrol@codehaus.org"
    end
    
    def test_fires_build_request_on_socket_accept
      
      build = @socket_trigger.do_accept(BuildBootstrapper.build_spec(
        @project_name, \
        @socket_triggercm_spec, \
        @build_command_line, \
        @nag_email))

      assert_got_message(BuildRequestEvent)
      build = messages_from_hub[0].build
      assert_equal(@project_name,       build.project_name)
      assert_equal(@socket_triggercm_spec,           build.scm_spec)
      assert_equal(@build_command_line, build.build_command_line)
      
    end

    def test_accepts_local_ip
      assert(@socket_trigger.allowed?("blah", "127.0.0.1"))
    end

    def test_accepts_local_host
      assert(@socket_trigger.allowed?("localhost", "128.0.0.1"))
    end

    def test_rejects_other
      assert(!@socket_trigger.allowed?("blah", "128.0.0.1"))
    end
    
    IPCONFIG_EXE_OUTPUT = <<-EOF

Windows IP Configuration


Ethernet adapter Local Area Connection:

        Media State . . . . . . . . . . . : Media disconnected

Ethernet adapter Wireless Network Connection:

        Connection-specific DNS Suffix  . : lan
        IP Address. . . . . . . . . . . . : 10.0.0.9
        Subnet Mask . . . . . . . . . . . : 255.0.0.0
        Default Gateway . . . . . . . . . : 10.0.0.138
    EOF
    
    def test_parses_ipconfig_output_on_windows
      assert_equal("(unknown)", 
        @socket_trigger.get_ip_from_ipconfig_exe_output("this is unparsable"))
      assert_equal("10.0.0.9", 
        @socket_trigger.get_ip_from_ipconfig_exe_output(IPCONFIG_EXE_OUTPUT))
    end

  end
  
end

