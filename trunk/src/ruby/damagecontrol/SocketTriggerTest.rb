require 'test/unit'

require 'damagecontrol/SocketTrigger'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'

require 'socket'

module DamageControl

  class SocketTriggerTest < Test::Unit::TestCase
    include FileUtils
    
    def setup
      @hub = Hub.new()
      @s = SocketTrigger.new(@hub, "/usr/local/builds")
      @project_name = "picocontainer"
      @scm_spec = ":local:/cvsroot/picocontainer:pico"
      @build_command_line = "\"echo damagecontrol rocks\""
    end

    def test_fires_build_request_on_socket_accept

      @s.do_accept(cvs_trigger_command)

      assert("picocontainer", @hub.last_message.build.project_name)
      
    end
        
    def test_trigger_command_for_cvs
      
      tc = cvs_trigger_command

      io = IO.popen(tc) do |io|
        io.each_line do |output|
          build = @s.create_build(output)
          
          assert_equal(@project_name,       build.project_name)
          assert_equal(@scm_spec,           build.scm_spec)
          assert_equal(@build_command_line, build.build_command_line)
          assert_equal("/usr/local/builds/picocontainer/pico/MAIN/checkout", build.checkout_dir)
          assert_equal("/usr/local/builds/picocontainer/pico/MAIN/checkout/pico/src", build.absolute_build_path)
        end
      end
      
      assert_equal("0", $?.to_s)
    end

  private
  
    def cvs_trigger_command
      build_path = "src"
      nc_command = cat_command # behaves like ncat without the network
      dc_host = ""
      dc_port = ""
      
      tc = @s.trigger_command(
        @project_name, \
        @scm_spec, \
        @build_command_line, \
        build_path, \
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

