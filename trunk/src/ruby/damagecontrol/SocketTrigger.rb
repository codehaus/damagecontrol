require 'damagecontrol/BuildRequestEvent'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'

require 'socket'

module DamageControl

	class SocketRequestEvent
		attr_reader :payload
		
		def initialize(payload)
			@payload = payload
		end
		
		def ==(other)
			other.is_a?(SocketRequestEvent) && \
				@payload == other.payload
		end
	end

	class SocketTrigger
	
		attr_accessor :port
		
		def initialize(hub)
			@hub = hub
			@port = 4711
		end
		
		def do_accept(payload)
			@hub.publish_message(SocketRequestEvent.new(payload))
		end
		
		def start
			Thread.new {
				begin
					puts "starting #{self}"
					$stdout.flush
					
					@server = TCPServer.new(port)
					puts "Server started"				
					$stdout.flush
					
					while (session = @server.accept)
						begin
							puts "got request"
							payload = session.gets
							puts "got request on socket: #{payload}"
							do_accept(payload)
							session.print("got your message\r\n\r\n")
						ensure
							session.close()
						end
					end
				rescue
					$stderr.print $!
					$stderr.print "\n"
					$stderr.print $!.backtrace.join("\n")
					$stderr.print "\n"
					@error = $!
				ensure
					puts "stopping #{self}"
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

