#$:<<'../../../../lib'
#$:<<'../..'

require 'test/unit' 
require 'mockit' 
require 'xmlrpc/server'
require 'xmlrpc/parser'
require 'webrick'
require 'rexml/document'
require 'net/http'
require 'damagecontrol/BuildScheduler'
require 'damagecontrol/BuildExecutor'
require 'damagecontrol/HubTestHelper'
require 'damagecontrol/xmlrpc/StatusPublisher'
require 'damagecontrol/BuildHistoryRepository'
require 'damagecontrol/AbstractBuildHistoryTest'

module DamageControl
module XMLRPC
  
  class StatusPublisherTest < AbstractBuildHistoryTest
    
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
      xmlrpc_servlet = ::XMLRPC::WEBrickServlet.new
      StatusPublisher.new(xmlrpc_servlet, @bhp)

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
      a = ""
      REXML::Document.new( data, pref ).write(a)
      b = ""
      REXML::Document.new( File.new("#{damagecontrol_home}/testdata/expected_xmlrpc_fetch_all_reply.xml"), pref).write(b)
      # Just compare the lengths. Not 100% foolproof, but if they're not equal, compare the actual content
      if(a.length != b.length)
        assert_equal(a,b)      
      end
    end
  end
  
end
end
