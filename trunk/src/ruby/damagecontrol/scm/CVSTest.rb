require 'test/unit'
require 'ftools'
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

      create_repo(testrepo)
      @cvs.install_trigger(
        testcheckout, \
        "testproject", \
        ":local:#{testrepo}:testmodule", \
        "echo dummybuild", \
        "localhost", \
        "4711", \
        ".", \
        "C:/scm/damagecontrol/bin/nc.exe"
      ) { |output|
        puts output
      }
    end

  private
  
    def create_repo(dir)
      File.mkpath(dir)
      Dir.chdir(dir)
      system("cvs -d:local:#{dir} init")
    end
  end
end