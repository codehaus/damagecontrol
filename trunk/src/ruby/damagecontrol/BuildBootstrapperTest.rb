require 'test/unit'
require 'damagecontrol/BuildBootstrapper'
require 'damagecontrol/FileUtils'

module DamageControl

  class BuildBootstrapperTest < Test::Unit::TestCase

    def test_trigger_command_for_cvs
      bs = BuildBootstrapper.new
      
      project_name = "picocontainer"
      scm_spec = ":local:/cvsroot/picocontainer:pico"
      build_command_line = "\"echo damagecontrol rocks\""
      build_path = "src"
      nc_command = cat_command # behaves like ncat without the network
      dc_host = ""
      dc_port = ""
      
      tc = bs.trigger_command(
        project_name, \
        scm_spec, \
        build_command_line, \
        build_path, \
        nc_command, \
        dc_host, \
        dc_port)

      io = IO.popen(tc) do |io|
        io.each_line do |output|
          build = bs.bootstrap_build(output, "/usr/local/builds")
          assert_equal(project_name,       build.project_name)
          assert_equal(scm_spec,           build.scm_spec)
          assert_equal(build_command_line, build_command_line)
          assert_equal("/usr/local/builds/picocontainer/pico/MAIN", build.checkout_dir)
          assert_equal("/usr/local/builds/picocontainer/pico/MAIN/pico/src", build.absolute_build_path)
        end
      end
      
      assert_equal("0", $?.to_s)
    end

  private
    include FileUtils
  
    def cat_command    
      if(windows?)
        File.expand_path("../../bin/cat.exe").gsub('/','\\')
      else
        "cat"
      end
    end

  end
end
