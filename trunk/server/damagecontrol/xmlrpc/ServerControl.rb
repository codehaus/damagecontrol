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
      meth 'string shutdown_with_message_and_time(string, int)', 'shut down server after specified time with message'
      meth 'string shutdown_with_message(string)', 'shut down server with message'
      meth 'string kill()', 'kill server (without running exit hooks)'
    }

    def initialize(xmlrpc_servlet, channel)
      @channel = channel
      xmlrpc_servlet.add_handler(INTERFACE, self)
    end
    
    def do_later(time=5)
      Thread.new do
        sleep time
        yield
      end
    end
    
    def shutdown_with_message_and_time(message, time)
      logger.info("request to shut down server in #{time} seconds: #{message}")
      @channel.publish_message(UserMessage.new(message))
      do_later(time) { exit ; sleep 2 ; exit! }
      "DamageControl server is shutting down within #{time} to #{time + 2} seconds"
    end
    
    def shutdown_with_message(message)
      shutdown_with_message_and_time("DamageControl server is shutting down in 5 secs", 5)
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
