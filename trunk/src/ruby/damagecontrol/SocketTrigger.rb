require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/Hub'
require 'damagecontrol/Project'

require 'socket'

module DamageControl

	class SocketTrigger
		
		def initialize(hub, project)
			@hub = hub
			@project = project
		end
		
		def do_accept()
			@hub.publish_message(BuildRequestEvent.new(@project))
		end
		
		def start
			Thread.new() {
				puts "Starting server"
				$stdout.flush
				
				@server = TCPServer.new(4711)
				puts "Server started"				
				$stdout.flush
				
				while (session = @server.accept)
					do_accept()
					session.print("got your message\r\n\r\n")
					session.close()
				end
			}
		end

	end

	#TODO - How do we start a server like this?
	def start_server()
		puts "Starting..."
		hub = Hub.new()
		s = SocketTrigger.new(hub, Project.new("Foo"))
		s.start_listening()
	
		sleep()
	end

end

