require 'xmlrpc/server'
require 'damagecontrol/Build'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/HubTestHelper'

module DamageControl

  class XMLRPCTrigger
    INTERFACE = XMLRPC::interface("build") {
      meth 'string request(string)', 'Request a build, passing in YAML config, returns status info', 'request'
    }

    def initialize(xmlrpc_server, channel)
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @bootstrapper = BuildBootstrapper.new
    end

    def request(build_yaml)
      @channel.publish_message(BuildRequestEvent.new(@bootstrapper.create_build(build_yaml)))
      "DamageControl got your message!"
    end
  end

end
