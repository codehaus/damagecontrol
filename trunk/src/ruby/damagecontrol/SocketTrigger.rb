require 'socket'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Hub'
require 'damagecontrol/Build'

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

	# This class listens for incoming connections. For each connection
	# it reads one line of payload which is sent to the hub wrapped in
	# a SocketRequestEvent object. Then it closes the connection and
	# listens for new connections.
	#
	# Consumes:
	# Emits: BuildRequestEvent
	#
	class SocketTrigger
	
		attr_accessor :port
		
		def initialize(hub, port=4711)
			@hub = hub
			@port = port
		end
		
		def do_accept(payload)
			@hub.publish_message(SocketRequestEvent.new(payload))
		end
		
		def start
			Thread.new {
				begin
					@server = TCPServer.new(port)
					puts "Starting SocketTrigger listening on port #{port}"
					$stdout.flush
					
					while (session = @server.accept)
						begin
							payload = session.gets
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
					puts "Stopped SocketTrigger listening on port #{port}"
				end
			}
		end

	end
end

