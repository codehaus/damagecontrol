require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/Logging'

module DamageControl
module XMLRPC

  class Trigger
    INTERFACE = ::XMLRPC::interface("build") {
      meth 'string trig(string, string)', 'trig(project_name, timestamp) is deprecated. Please use request instead'
      meth 'string request(string)', 'Requests a build, specifying project name'
    }
    
    include Logging

    def initialize(xmlrpc_server, channel, project_configuration_repository, checkout_manager, public_web_url)
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @project_configuration_repository = project_configuration_repository
      @checkout_manager = checkout_manager
      @public_web_url = public_web_url
    end

    # deprecated
    def trig(project_name, timestamp)
      trig(project_name)
    end

    def request(project_name)
      begin
        changesets_or_last_commit_time = @checkout_manager.checkout(project_name)
        build = @project_configuration_repository.create_build(project_name)
        if(changesets_or_last_commit_time.is_a?(ChangeSets))
          build.changesets = changesets_or_last_commit_time
        end
        @channel.publish_message(BuildRequestEvent.new(build))
        
<<-EOF
Monitor build results at:
#{@public_web_url}project?project_name=#{project_name}
EOF
      rescue => e
        logger.error(e)
        <<-EOF
        DamageControl exception:
        #{e.message}
        EOF
      end
    end
    
    # The trigger command that will trig a build for a certain project
    def Trigger.trigger_command(damagecontrol_install_dir, project_name, trigger_xml_rpc_url="http://localhost:4712/private/xmlrpc")
      script = "sh #{damagecontrol_install_dir}/bin/requestbuild"
      "#{script} --url #{trigger_xml_rpc_url} --projectname #{project_name}"
    end

  end

end
end
