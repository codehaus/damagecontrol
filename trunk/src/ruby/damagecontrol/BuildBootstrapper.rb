require 'damagecontrol/SocketTrigger'
require 'damagecontrol/AsyncComponent'

module DamageControl
	class BuildBootstrapper < AsyncComponent
		def initialize(hub, basedir)
			super(hub)
			@basedir = basedir
		end
		
		def bootstrap_build(build_spec)
			command, project_name, scm_path, build_command_line = build_spec.split
			build = Build.new(project_name)
			build.basedir = "#{@basedir}/#{project_name}"
			build.build_command_line = build_command_line
			build.scm_path = scm_path
			build
		end
		
		def process_message(message)
			if (message.is_a?(SocketRequestEvent))
				build = bootstrap_build(message.payload)
				hub.publish_message(BuildRequestEvent.new(build))
			end
			consume_message(message)
		end
	end
end