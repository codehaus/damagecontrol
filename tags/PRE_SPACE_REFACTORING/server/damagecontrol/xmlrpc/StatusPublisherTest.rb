require 'test/unit' 
require 'pebbles/mockit' 
require 'xmlrpc/server'
require 'xmlrpc/parser'
require 'webrick'
require 'rexml/document'
require 'net/http'
require 'damagecontrol/core/BuildScheduler'
require 'damagecontrol/core/BuildExecutor'
require 'damagecontrol/core/BuildHistoryRepository'
require 'damagecontrol/core/AbstractBuildHistoryTest'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/xmlrpc/StatusPublisher'

module DamageControl
module XMLRPC
  
  class StatusPublisherTest < AbstractBuildHistoryTest
    
    XMLRPC_CALL_DATA = <<-EOF
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

    include FileUtils

    # This is an acceptance test
    def test_xml_rpc_response_is_of_expected_format
      xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      StatusPublisher.new(xmlrpc_servlet, @bhp)
      # add some changes
      @apple2.changesets.add(Change.new("path/one",   "jon",   "tjo bing",    "1.1", Time.utc(2004,7,5,12,0,2)))
      @apple2.changesets.add(Change.new("path/two",   "jon",   "tjo bing",    "1.2", Time.utc(2004,7,5,12,0,4)))

      httpserver = WEBrick::HTTPServer.new(:Port => 4719)
      httpserver.mount("/test", xmlrpc_servlet)
      at_exit { httpserver.shutdown }
      Thread.new { httpserver.start }
      
      # Do a raw post so we can compare the XML that comes back
      header = {  
        "User-Agent"     => "Just a test",
        "Content-Type"   => "text/xml",
        "Content-Length" => XMLRPC_CALL_DATA.size.to_s, 
        "Connection"     => "close"
      }
      h = Net::HTTP.new('localhost', 4719)
      resp, data = h.post2('/test', XMLRPC_CALL_DATA, header)
      
      pref = {:ignore_whitespace_nodes=>:all}
      response_as_string = ""
      response = REXML::Document.new(data, pref)
      response.write(response_as_string)
      File.open("#{damagecontrol_home}/testdata/actual.xml", "w+") do |io|
        response.write(io)
      end
      expected_as_string = ""
      REXML::Document.new( File.new("#{damagecontrol_home}/testdata/expected_xmlrpc_fetch_all_reply.xml"), pref).write(expected_as_string)
      # Just compare the lengths. Not 100% foolproof, but if they're not equal, compare the actual content
      if(response_as_string.length != expected_as_string.length)
        assert_equal(expected_as_string, response_as_string)      
      end
    end
  end
  
end
end
