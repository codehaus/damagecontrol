require 'test/unit' 
require 'thread'
require 'pebbles/mockit' 
require 'xmlrpc/server'
require 'xmlrpc/parser'
require 'webrick'
require 'rexml/document'
require 'net/http'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/core/BuildSerializer'
require 'damagecontrol/xmlrpc/StatusPublisher'
require 'rubygems'
require 'rscm'

module DamageControl
module XMLRPC
  
  class StatusPublisherTest < Test::Unit::TestCase
    
    XMLRPC_HISTORY_DATA = <<-EOF
    <?xml version="1.0" encoding="ISO-8859-1"?>
    <methodCall>
      <methodName>status.history</methodName>
      <params>
        <param>
          <value>
            <string>apple</string>
          </value>
        </param>
      </params>
    </methodCall>
    EOF

    XMLRPC_PROJECT_NAMES_DATA = <<-EOF
    <?xml version="1.0" encoding="ISO-8859-1"?>
    <methodCall>
      <methodName>status.project_names</methodName>
    </methodCall>
    EOF

    XMLRPC_CURRENT_BUILD_DATA = <<-EOF
    <?xml version="1.0" encoding="ISO-8859-1"?>
    <methodCall>
      <methodName>status.current_build</methodName>
      <params>
        <param>
          <value>
            <string>apple</string>
          </value>
        </param>
      </params>
    </methodCall>
    EOF

    include FileUtils
    include MockIt

    def setup
      @apple1 = Build.new("apple", {"build_command_line" => "Apple1"})
      @apple1.status = Build::SUCCESSFUL
      @apple1.dc_creation_time = Time.utc(2004,3,16,22,59,46)

      @pear1 = Build.new("pear", {"build_command_line" => "Pear1"})
      @pear1.dc_creation_time = Time.utc(2004,3,16,22,59,47)
      
      @apple2 = Build.new("apple", {"build_command_line" => "Apple2"})
      @apple2.status = Build::FAILED
      @apple2.dc_creation_time = Time.utc(2004,3,16,22,59,48)

      # add some changes
      @apple2.changesets.add(RSCM::Change.new("path/one",   "jon",   "tjo bing",    "1.1", Time.utc(2004,7,5,12,0,2)))
      @apple2.changesets.add(RSCM::Change.new("path/two",   "jon",   "tjo bing",    "1.2", Time.utc(2004,7,5,12,0,4)))

      @bhp = new_mock

      @httpserver = WEBrick::HTTPServer.new(:Port => 4719)
      Thread.new { @httpserver.start }
    end
    
    def teardown
      @httpserver.shutdown
      # lame way to wait for webrick to shut down :-(
      # can someone grok how to wait for webrick to shut down?
      sleep(2)
    end

    def test_history
      @bhp.__expect(:history) {[@apple1, @apple2]}
      test_xml_rpc_response_is_of_expected_format(XMLRPC_HISTORY_DATA, "expected_xmlrpc_history_reply.xml")
    end

    def test_project_names
      @bhp.__expect(:project_names) {["apple", "pear"]}
      test_xml_rpc_response_is_of_expected_format(XMLRPC_PROJECT_NAMES_DATA, "expected_xmlrpc_project_names_reply.xml")
    end

    def test_current_build
      @bhp.__expect(:current_build) {@apple2}
      test_xml_rpc_response_is_of_expected_format(XMLRPC_CURRENT_BUILD_DATA, "expected_xmlrpc_current_build_reply.xml")
    end

    # This is an acceptance test
    def test_xml_rpc_response_is_of_expected_format(xml_rpc_call_data, expected)
      xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      StatusPublisher.new(xmlrpc_servlet, @bhp)

      @httpserver.mount("/test", xmlrpc_servlet)
      
      # Do a raw post so we can compare the XML that comes back
      header = {  
        "User-Agent"     => "Just a test",
        "Content-Type"   => "text/xml",
        "Content-Length" => xml_rpc_call_data.size.to_s, 
        "Connection"     => "close"
      }
      h = Net::HTTP.new('localhost', 4719)
      resp, data = h.post2('/test', xml_rpc_call_data, header)
      
      pref = {:ignore_whitespace_nodes=>:all}
      response_as_string = ""
      response = REXML::Document.new(data, pref)
      response.write(response_as_string)
      expected_as_string = ""
      REXML::Document.new(File.new(File.dirname(__FILE__) + "/#{expected}"), pref).write(expected_as_string)
      # Just compare the lengths. Not 100% foolproof, but if they're not equal, compare the actual content
      if(expected_as_string.length != response_as_string.length)
        assert_equal(expected_as_string, response_as_string)      
      end
    end
  end
  
end
end
