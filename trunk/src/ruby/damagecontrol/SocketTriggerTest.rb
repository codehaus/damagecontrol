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
      @s = SocketTrigger.new(hub)
      @project_name = "picocontainer"
      @scm_spec = ":local:/cvsroot/picocontainer:pico"
      @build_command_line = "echo damagecontrol rocks"
      @nag_email = "damagecontrol@codehaus.org"
    end
    
    def test_fires_build_request_on_socket_accept
      
      build = @s.do_accept(cvs_build_spec)

      assert_got_message(BuildRequestEvent)
      build = messages_from_hub[0].build
      assert_equal(@project_name,       build.project_name)
      assert_equal(@scm_spec,           build.scm_spec)
      assert_equal(@build_command_line, build.build_command_line)
      
    end

    def test_accepts_local_ip
      assert(@s.allowed?("blah", "127.0.0.1"))
    end

    def test_accepts_local_host
      assert(@s.allowed?("localhost", "128.0.0.1"))
    end

    def test_rejects_other
      assert(!@s.allowed?("blah", "128.0.0.1"))
    end

  private
  
    def cvs_build_spec
      nc_command = cat_command # behaves like ncat without the network
      dc_host = ""
      dc_port = ""
      
      tc = BuildBootstrapper.build_spec(
        @project_name, \
        @scm_spec, \
        @build_command_line, \
        @nag_email, \
        nc_command, \
        dc_host, \
        dc_port)
    end
  
    def cat_command
      if(windows?)
        File.expand_path("#{damagecontrol_home}/bin/cat.exe").gsub('/','\\')
      else
        "cat"
      end
    end

  end
  
end

