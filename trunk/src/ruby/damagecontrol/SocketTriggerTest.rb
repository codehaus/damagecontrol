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
    end
    
    def test_fires_build_request_on_socket_accept

      @s.do_accept(cvs_trigger_command)
      
    end
        
    def test_fires_build_request_on_socket_accept
      
      tc = cvs_trigger_command

      io = IO.popen(tc) do |io|
        io.each_line do |output|
          build = @s.do_accept(output)
          
          assert_got_message(BuildRequestEvent)
          build = messages_from_hub[0].build
          assert_equal(@project_name,       build.project_name)
          assert_equal(@scm_spec,           build.scm_spec)
          assert_equal(@build_command_line, build.build_command_line)
        end
      end
      
      assert_equal("0", $?.to_s)
    end

    def TODO_test_uses_modification_from_request_payload
      
    end

    def TODO_test_includes_all_modifications_since_last_succesful_build
      
    end

    def TODO_test_resets_modification_set_on_succesful_build
      
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
  
    def cvs_trigger_command
      nc_command = cat_command # behaves like ncat without the network
      dc_host = ""
      dc_port = ""
      
      tc = @s.trigger_command(
        @project_name, \
        @scm_spec, \
        @build_command_line, \
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

