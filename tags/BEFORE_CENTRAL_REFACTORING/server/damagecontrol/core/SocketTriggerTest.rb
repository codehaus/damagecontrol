require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/SocketTrigger'
require 'damagecontrol/core/Hub'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/HubTestHelper'

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
      @socket_trigger_scm_spec = ":local:/cvsroot/picocontainer:pico"
      @build_command_line = "echo damagecontrol rocks"
      @nag_email = "damagecontrol@codehaus.org"
    end

    def test_prints_error_message_on_disallowed_host
      socket = MockIt::Mock.new
      socket.__setup(:peeraddr) { [nil, nil, "host.evil.com", "0.6.6.6"] }
      socket.__expect(:print) {|message|
        assert_match(/doesn.t allow/, message)
        assert_match(/host.evil.com/, message)
        assert_match(/0.6.6.6/, message)
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
      build_yaml = BuildBootstrapper.build_spec(
              @project_name, \
              @socket_trigger_scm_spec, \
              @build_command_line, \
        @nag_email)
      
      @socket_trigger.process_payload(build_yaml)

      assert_got_message(BuildRequestEvent)
      build = messages_from_hub[0].build
      assert_equal(@project_name, build.project_name)
      assert_equal(@socket_trigger_scm_spec, build.scm_spec)
      assert_equal(@build_command_line, build.build_command_line)
      
    end

    def TODO_FAILS_test_string_starting_with_colon_can_be_yamled
      map = ["foo" => ":bar:zap"]
      map_yaml = YAML::dump(map)
      puts map_yaml
      yamled_map = YAML::load(map_yaml)
      assert_equal(map, yamled_map)
    end
  end
  
end

