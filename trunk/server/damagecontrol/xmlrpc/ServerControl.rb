require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/Logging'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/BuildHistoryRepository'

# Authors: Jon Tirsen
module DamageControl
module XMLRPC

  class ServerControl
  
    include Logging
  
    PING_RESPONSE = "Response from DamageControl"
  
    INTERFACE = ::XMLRPC::interface("control") {
      meth 'string shutdown()', 'shut down the server'
      meth 'string kill()', 'kill server (without running exit hooks)'
    }

    def initialize(xmlrpc_servlet)
      xmlrpc_servlet.add_handler(INTERFACE, self)
    end
    
    def do_later
      Thread.new do
        sleep 2
        yield
      end
    end
    
    def shutdown
      logger.info("request to shut down server")
      do_later { exit }
      ""
    end
    
    def kill
      logger.info("request to kill server (without running exit hooks)")
      do_later { exit! }
      ""
    end
  end

end
end
