require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'

module DamageControl
module XMLRPC

  class Trigger
    INTERFACE = ::XMLRPC::interface("build") {
      meth 'string trig(string, string)', 'Trigs a build, specifying project name and timestamp in GMT formatted YYYYMMDDHHMMSS'
    }
    
    include Logging

    def initialize(xmlrpc_server, channel, project_configuration_repository)
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @project_configuration_repository = project_configuration_repository
    end

    def trig(project_name, timestamp)
      begin
        build = @project_configuration_repository.create_build(project_name, timestamp)
        build.status = Build::QUEUED
        @channel.publish_message(BuildRequestEvent.new(build))
        
<<-EOF
DamageControl server requests build for #{project_name} on #{timestamp}. Monitor build results at:
http://builds.codehaus.org/public/project?project_name=#{project_name}
irc://irc.codehaus.org/damagecontrol/
EOF
      rescue => e
        logger.error(e)
        <<-EOF
        DamageControl exception:
        #{e.message}
        EOF
      end
    end
  end

end
end
