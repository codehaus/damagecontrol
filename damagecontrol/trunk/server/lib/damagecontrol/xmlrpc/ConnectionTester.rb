require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/BuildHistoryRepository'

# Authors: Jon Tirsen
module DamageControl
module XMLRPC

  class ConnectionTester
  
    include Logging
  
    PING_RESPONSE = "Response from DamageControl"
  
    INTERFACE = ::XMLRPC::interface("test") {
      meth 'string echo(string)', 'returns a map of array of build, project name as key.', 'echo'
      meth 'string ping()', 'will return #{PING_RESPONSE}.', 'ping'
    }

    def initialize(xmlrpc_servlet)
      xmlrpc_servlet.add_handler(INTERFACE, self)
    end
    
    def echo(what)
      logger.info("got echo request #{what}")
      what
    end
    
    def ping
      logger.info("got ping request")
      PING_RESPONSE
    end
  end

end
end
