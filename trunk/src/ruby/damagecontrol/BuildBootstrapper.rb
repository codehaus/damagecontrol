require 'damagecontrol/SocketTrigger'

module DamageControl
	class BuildBootstrapper
		def initialize(hub, basedir)
			@hub = hub
			@hub.add_subscriber(self)
			@basedir = basedir
		end
		
		def bootstrap_build(build_spec)
			command, project_name, cvsroot, build_command_line = build_spec.split
			build = Build.new(project_name)
			def build.build
				puts "building #{self}"
				super()
				puts "built #{self}"
			end
			build.basedir = "#{@basedir}/#{project_name}"
			build.build_command_line = build_command_line
			build
		end
		
		def receive_message(message)
			if (message.is_a?(SocketRequestEvent))
				build = bootstrap_build(message.payload)
				@hub.publish_message(BuildRequestEvent.new(build))
			end
		end
	end
end