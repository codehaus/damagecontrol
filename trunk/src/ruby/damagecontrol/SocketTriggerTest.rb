require 'test/unit'
require 'mockit'

require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'
require 'damagecontrol/HubTestHelper'

require 'socket'

module DamageControl

  class HostVerifierTest < Test::Unit::TestCase
    def setup
      @verifier = HostVerifier.new
    end

    def test_accepts_local_ip
      assert(@verifier.allowed?("blah", "127.0.0.1"))
    end

    def test_accepts_local_host
      assert(@verifier.allowed?("localhost", "128.0.0.1"))
    end

    def test_rejects_other
      assert(!@verifier.allowed?("host.evil.com", "0.6.6.6"))
    end    
  end

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

    def test_prints_error_message_on_disallowed_host
      socket = MockIt::Mock.new
      socket.__setup(:peeraddr) { [nil, nil, "host.evil.com", "0.6.6.6"] }
      socket.__expect(:print) {|message|
        assert_match(message, /doesn.t allow/)
        assert_match(message, /host.evil.com/)
        assert_match(message, /0.6.6.6/)
      }
      socket.__expect(:close) { }
      verifier = MockIt::Mock.new
      verifier.__expect(:allowed?) {|host, ip| 
        assert_equal("host.evil.com", host)
        assert_equal("0.6.6.6", ip)
      }
      @socket_trigger.host_verifier = verifier
      @socket_trigger.do_accept(socket)
      verifier.__verify
      socket.__verify
      assert_message_types_from_hub([])
    end
    
    def test_fires_build_request_on_socket_accept
      
      build = @socket_trigger.process_payload(BuildBootstrapper.build_spec(
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

