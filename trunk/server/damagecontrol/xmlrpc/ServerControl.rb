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
      meth 'string shutdown_with_message(string)', 'shut down server with message'
      meth 'string kill()', 'kill server (without running exit hooks)'
    }

    def initialize(xmlrpc_servlet, channel)
      @channel = channel
      xmlrpc_servlet.add_handler(INTERFACE, self)
    end
    
    def do_later
      Thread.new do
        sleep 5
        yield
      end
    end
    
    def shutdown_with_message(message)
      logger.info("request to shut down server: #{message}")
      @channel.publish_message(UserMessage.new(message))
      do_later { exit ; sleep 2 ; exit! }
      "DamageControl server is shutting down within 5 to 7 seconds"
    end
    
    def shutdown
      shutdown_with_message("DamageControl server is shutting down in 5 secs")
    end
    
    def kill
      logger.info("request to kill server (without running exit hooks)")
      do_later { exit! }
      ""
    end
  end

end
end
