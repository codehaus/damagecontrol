require 'xmlrpc/server'
require 'damagecontrol/Build'
require 'damagecontrol/BuildEvents'

module DamageControl

  class XMLRPCStatusPublisher
  
    INTERFACE = XMLRPC::interface("status") {
      meth 'string status(string)', 'Request status of a build, passing in the project name, returns status info', 'status'
    }

    def initialize(xmlrpc_server, channel)
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @channel.add_subscriber(self)
      @status = {}
    end
    
    def receive_message(message)
      if (message.is_a?(BuildRequestEvent))
        @status[message.build.project_name] = "Scheduled"
      elsif (message.is_a?(BuildStartedEvent))
        @status[message.build.project_name] = "In progress"
      elsif (message.is_a?(BuildCompleteEvent))
        if (message.build.successful)
          @status[message.build.project_name] = "Built at #{message.build.timestamp}"
        else
          @status[message.build.project_name] = "Failed at #{message.build.timestamp}"
        end
      end      
    end
    
    def status(project_name)
      result = @status[project_name]
      if (result.nil?)
        "Unknown"
      else
        result
      end
    end
  end

end
