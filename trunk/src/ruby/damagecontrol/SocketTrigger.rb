require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'

require 'socket'

module DamageControl

	class SocketTrigger
	
		attr_accessor :port
		
		def initialize(hub, build)
			@hub = hub
			@build = build
			@port = 4711
		end
		
		def do_accept()
			@hub.publish_message(BuildRequestEvent.new(@build))
		end
		
		def start
			Thread.new() {
				puts "Starting server"
				$stdout.flush
				
				@server = TCPServer.new(port)
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
		s = SocketTrigger.new(hub, Build.new("Foo"))
		s.start_listening()
	
		sleep()
	end

end

