#$:<<'../../../../lib'
#$:<<'../..'

require 'test/unit' 
require 'mockit' 
require 'xmlrpc/server'
require 'xmlrpc/parser'
require 'webrick'
require 'net/http'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/publisher/XMLRPCStatusPublisher'
require 'damagecontrol/publisher/BuildHistoryPublisher'
require 'damagecontrol/publisher/AbstractBuildHistoryTest'

module DamageControl
  
  class XMLRPCStatusPublisherTest < AbstractBuildHistoryTest
    
    XMLRPC_CALL_DATA = <<-EOF
    <?xml version="1.0" encoding="ISO-8859-1"?>
      <methodCall>
        <methodName>status.get_build_list_map</methodName>
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
      xmlrpc_servlet = XMLRPC::WEBrickServlet.new
      XMLRPCStatusPublisher.new(xmlrpc_servlet, @bhp)

      httpserver = WEBrick::HTTPServer.new(:Port => 4719)
      httpserver.mount("/test", xmlrpc_servlet)
      at_exit { httpserver.shutdown }
      Thread.new { httpserver.start }
      
      # Do a raw post so we can compare the XML that comes back
      header = {  
        "User-Agent"     =>  "Just a test",
        "Content-Type"   => "text/xml",
        "Content-Length" => XMLRPC_CALL_DATA.size.to_s, 
        "Connection"     => "close"
      }
      h = Net::HTTP.new('localhost', 4719)
      resp, data = h.post2('/test', XMLRPC_CALL_DATA, header)
      
      parser = XMLRPC::XMLParser::XMLParser.new
      actual_build_list_map = parser.parseMethodResponse(data)

      # Read the expected file and make it one line (the xml rpc client is a bit flaky)
      expected_data = File.new("#{damagecontrol_home}/testdata/expected_xmlrpc_fetch_all_reply.xml").read.gsub(/[ \r\n]/, "").sub(/xmlversion/, "xml version")
      expected_build_list_map = parser.parseMethodResponse(expected_data)      
      
      assert_equal(expected_build_list_map, actual_build_list_map)
    end
  end
end
