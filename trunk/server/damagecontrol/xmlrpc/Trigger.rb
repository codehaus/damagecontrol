require 'xmlrpc/server'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/Logging'

module DamageControl
module XMLRPC

  class Trigger
    DEPRECATED_MESSAGE = 'The trig(project_name, timestamp) method is deprecated. Please use request(project_name) instead'
    INTERFACE = ::XMLRPC::interface("build") {
      meth 'string trig(string, string)', DEPRECATED_MESSAGE
      meth 'string request(string)', 'Requests a build, specifying project name'
    }
    
    include Logging

    def initialize(xmlrpc_server, channel, project_config_repository, checkout_manager, public_web_url)
      xmlrpc_server.add_handler(INTERFACE, self)
      @channel = channel
      @project_config_repository = project_config_repository
      @checkout_manager = checkout_manager
      @public_web_url = public_web_url
    end

    # deprecated
    def trig(project_name, timestamp)
      result = request(project_name)
      message = "\n#{DEPRECATED_MESSAGE}\n#{result}"
      message
    end

    def request(project_name)
      begin
        build = @project_config_repository.create_build(project_name)
        build.status = Build::CHECKING_OUT
        @channel.publish_message(BuildRequestEvent.new(build))

        changesets_or_last_commit_time = @checkout_manager.checkout(project_name)
        if(changesets_or_last_commit_time.is_a?(ChangeSets))
          build.changesets = changesets_or_last_commit_time
        end
        
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
