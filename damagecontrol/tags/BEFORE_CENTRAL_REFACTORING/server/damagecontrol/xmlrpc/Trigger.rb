require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/HubTestHelper'

module DamageControl
module XMLRPC

  class Trigger
    INTERFACE = ::XMLRPC::interface("build") {
      meth 'string request(string)', 'Request a build, passing in YAML config, returns status info', 'request'
    }

    def initialize(xmlrpc_server, channel)
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @build_bootstrapper = BuildBootstrapper.new
    end

    def request(build_yaml)
      build = @build_bootstrapper.create_build(build_yaml)
      build.status = Build::QUEUED
      @channel.publish_message(BuildRequestEvent.new(build))
      "DamageControl got your message!"
    end
  end

end
end
