require 'test/unit'
require 'ftools'
require 'socket'
require 'damagecontrol/scm/CVS'
require 'damagecontrol/FileUtils'

module DamageControl
  class CVSTest < Test::Unit::TestCase
    include FileUtils
  
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
      root = to_os_path("/some/where")
      assert_equal(
        "-d :pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol checkout -d #{root} damagecontrol", \
        @cvs.checkout_command(":pserver:anonymous@cvs.codehaus.org:/cvsroot/damagecontrol:damagecontrol", "/some/where"))
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
      testrepo = File.expand_path("#{damagecontrol_home}/target/cvstestrepo")
      testcheckout = File.expand_path("#{damagecontrol_home}/target/cvstestcheckout/CVSROOT")
      
      project_name = "DamageControlled"
      spec = ":local:#{testrepo}:damagecontrolled"
      build_command = "echo hello"
      nag_email = "maillist@project.bar"

      mock_server = start_mock_server(self)

      pwd = Dir.getwd
      create_repo(testrepo)
      Dir.chdir(pwd)
      @cvs.install_trigger(
        testcheckout, \
        project_name, \
        spec, \
        build_command, \
        nag_email, \
        "localhost", \
        "4713", \
        nc_exe
      ) { |output|
        #puts output
      }

      import_damagecontrolled(testcheckout, spec)      
      
      # wait for max 2 secs. if mock server is still waiting, it's a failure
      mock_server.join(2)
      assert(!mock_server.alive?, "mock server didn't get incoming connection")
      mock_server.kill
            
      @cvs.checkout(spec, testcheckout) {|output|
        puts "HALLO" + output
      }
    end

  private
  
    def nc_exe
      if(windows?)
        File.expand_path("#{damagecontrol_home}/bin/nc.exe").gsub('/','\\')
      else
        nil
      end
    end

    def create_repo(dir)
      File.mkpath(dir)
      Dir.chdir(dir)
      system("cvs -d:local:#{dir} init")
    end
    
    def import_damagecontrolled(testcheckout, spec)
      Dir.chdir("#{damagecontrol_home}/testdata/damagecontrolled")
      cmd = "cvs -d#{@cvs.cvsroot(spec)} -q import -m \"\" #{@cvs.mod(spec)} dc-vendor dc-release"
      system(cmd)
    end

    def start_mock_server(test)
      Thread.abort_on_exception = true
      Thread.new {
        socket = TCPServer.new(4713).accept
        payload = ""
        socket.each { |line|
          payload << line
          if(line.chomp == "...")
            break
          end
        }
        socket.close
      }
    end
  end


  class CVSLogParserTest < Test::Unit::TestCase
  
    include FileUtils
    
    def setup
      @parser = CVSLogParser.new
    end
    
    def test_extracts_log_entries
      def @parser.number_of_entries; @number_of_entries end
      def @parser.parse_modifications(log_entry)
        @number_of_entries = 0 unless defined?(@number_of_entries)
        @number_of_entries+=1
        []
      end
  
      File.open("#{damagecontrol_home}/testdata/cvs-test.log") do |io|
        @parser.parse_log(io)
      end
      assert_equal(220, @parser.number_of_entries)
    end
    
    
    def test_parse_modifications
      modifications = @parser.parse_modifications(LOG_ENTRY)
      assert_equal(4, modifications.length)
      assert_equal("/cvsroot/damagecontrol/damagecontrol/src/ruby/damagecontrol/BuildExecutorTest.rb", modifications[0].path)
    end
    

    def test_parse_modification
      modification = @parser.parse_modification(MODIFICATION_ENTRY)
      assert_equal("1.20", modification.revision)
      assert_equal("2003/11/09 17:53:37", modification.time)
      assert_equal("tirsen", modification.developer)
    end

    MODIFICATION_ENTRY = <<-EOF
    revision 1.20
    date: 2003/11/09 17:53:37;  author: tirsen;  state: Exp;  lines: +3 -4
    Quiet period is configurable for each project
    EOF
    
    LOG_ENTRY = <<-EOF
    =============================================================================
    
    RCS file: /cvsroot/damagecontrol/damagecontrol/src/ruby/damagecontrol/BuildExecutorTest.rb,v
    Working file: src/ruby/damagecontrol/BuildExecutorTest.rb
    head: 1.20
    branch:
    locks: strict
    access list:
    symbolic names:
    keyword substitution: kv
    total revisions: 20;    selected revisions: 4
    description:
    ----------------------------
    revision 1.20
    date: 2003/11/09 17:53:37;  author: tirsen;  state: Exp;  lines: +3 -4
    Quiet period is configurable for each project
    ----------------------------
    revision 1.19
    date: 2003/11/09 17:04:18;  author: tirsen;  state: Exp;  lines: +32 -2
    Quiet period implemented for BuildExecutor, but does not yet handle multiple projects (builds are not queued as before)
    ----------------------------
    revision 1.18
    date: 2003/11/09 15:51:50;  author: rinkrank;  state: Exp;  lines: +1 -2
    linux/windows galore
    ----------------------------
    revision 1.17
    date: 2003/11/09 15:00:06;  author: rinkrank;  state: Exp;  lines: +6 -8
    o YAML config (BuildBootstrapper)
    o EmailPublisher
    =============================================================================
    EOF

  end

end