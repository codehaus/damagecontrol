require 'test/unit'
require 'ftools'
require 'socket'
require 'damagecontrol/scm/CVS'

module DamageControl
  class CVSTest < Test::Unit::TestCase
    def setup
      @cvs = CVS.new
    end
    
    def test_parse_local_unix_spec
      protocol = "local"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      spec     = ":#{protocol}:#{path}:#{mod}"

      assert_equal([protocol, nil, nil, path, mod], @cvs.parse_spec(spec))
      assert_equal(":local:/cvsroot/damagecontrol", @cvs.cvsroot(spec))
    end

    def test_parse_local_windows_spec
      protocol = "local"
      path     = "C:\\pling\\plong"
      mod      = "damagecontrol"

      spec     = ":#{protocol}:#{path}:#{mod}"

      assert_equal([protocol, nil, nil, path, mod], @cvs.parse_spec(spec))
      assert_equal(":local:C:\\pling\\plong", @cvs.cvsroot(spec))
    end
    
    def test_tokens
      spec = ":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"
      assert_equal("pserver",                @cvs.protocol(spec))
      assert_equal("anonymous",              @cvs.user(spec))
      assert_equal("cvs.codehaus.org",       @cvs.host(spec))
      assert_equal("/cvsroot/damagecontrol", @cvs.path(spec))
      assert_equal("damagecontrol",          @cvs.mod(spec))
    end
    
    def test_parse_pserver_spec
      protocol = "pserver"
      user     = "anonymous"
      host     = "cvs.codehaus.org"
      path     = "/cvsroot/damagecontrol"
      mod      = "damagecontrol"

      spec     = ":#{protocol}:#{user}@#{host}:#{path}:#{mod}"

      assert_equal([protocol, user, host, path, mod], @cvs.parse_spec(spec))
      assert_equal(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol", @cvs.cvsroot(spec))
    end
    
    def test_checkout_command
      assert_equal(
        "-d :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol co damagecontrol", \
        @cvs.checkout_command(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"))
    end
    
    def test_update_command
      assert_equal(
        "-d :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol update -d -P", \
        @cvs.update_command(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol"))
    end
    
    def test_does_not_handle_starteam_path
      assert(!@cvs.handles_spec?("starteam://username:password@server/project/view/folder"))
    end

    def test_install_trigger
    
      testrepo = File.expand_path("target/cvstestrepo")
      testcheckout = File.expand_path("target/cvstestcheckout")
      
      project_name = "testproject"
      spec = ":local:#{testrepo}:testmodule"
      build_command = "echo dummybuild"

      expected = "#{project_name} #{spec.gsub('/','\\')} #{build_command} ."
      mock_server = start_mock_server(self, expected)

      create_repo(testrepo)
      @cvs.install_trigger(
        testcheckout, \
        project_name, \
        spec, \
        build_command, \
        "localhost", \
        "4713", \
        ".", \
        "C:/scm/damagecontrol/bin/nc.exe"
      ) { |output|
        #puts output
      }

      import_module(testcheckout, spec)      
      
      # wait for max 2 secs. if mock server is still waiting, it's a failure
      mock_server.join(2)
      assert(!mock_server.alive?, "mock server didn't get incoming connection")
      mock_server.kill
    end

  private
  
    def create_repo(dir)
      File.mkpath(dir)
      Dir.chdir(dir)
      system("cvs -d:local:#{dir} init")
    end
    
    def import_module(testcheckout, spec)
      module_dir = "#{testcheckout}/#{@cvs.mod(spec)}"

      File.mkpath(module_dir)
      File.open("#{module_dir}/afile.txt", "w") do |file|
        file.puts "yo"
      end      

      Dir.chdir("#{testcheckout}")
      system("cvs -d#{@cvs.cvsroot(spec)} -q import -m \"\" #{@cvs.mod(spec)} dc-vendor dc-release")
    end

    def start_mock_server(test, expected)
      Thread.abort_on_exception = true
      Thread.new {
        session = TCPServer.new(4713).accept
        payload = session.gets
        session.close()
#        test.assert_equal(expected, payload)
      }
    end
  end
end