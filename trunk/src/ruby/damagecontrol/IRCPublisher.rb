$:<<"../../lib/rica"

require 'rica'

module DamageControl

	class IRCPublisher
	
		include TimerMixin
	
		class IRCConnection < Rica::MessageProcessor
			
			def initialize(channel)
				super()
				@channel = channel
			end
		
			def default_action(msg)
				puts(msg.string("%T %s %t:%f %C %a"))
			end
		
			def on_link_established(msg)
				@current_server=msg.server
				@current_channel=nil
				puts(msg.string("%T %s Link Established"))
				join_channel
			end
	
			def on_link_closed(msg)
				@current_server=nil
				@current_channel=nil
			end

			def join_channel
				if(!in_channel?)
					cmnd_join(@current_server, @channel)
				end
			end
	
			#
			# respond to join
			#
			def on_recv_cmnd_join(msg)
				@current_channel=msg.to
			end
			
			def connected?
				!@current_server.nil?
			end
	
			def in_channel?
				!@current_channel.nil?
			end
			
			def send_message_to_channel(message)
				cmnd_privmsg(@current_server, \
					@current_channel, \
					message)
			end
		
			def connect(server)
				self.open(server,['damagecontrol','DamageControl Example'],'dcontrol')
			end
	
		end
	
		def initialize(hub, server, channel)
			super()
			hub.add_subscriber(self)
			@inq = Queue.new
			@irc = IRCConnection.new(channel)
			@server = server
		end
		
		
		def tick(time)
			schedule_next_tick
			if !@inq.empty?
				process_message(@inq.deq)
			end
		end
	
		def process_message(message)
			if message.is_a?(BuildCompleteEvent)
				if @irc.connected? && @irc.in_channel?
					@irc.send_message_to_channel("BUILD COMPLETE, check webpage for more info")
				else
					pushback_message(message)
					@irc.connect(@server) unless @irc.connected?
					@irc.join_channel if @irc.connected? && !@irc.in_channel?
				end
			end
		end
		
		def pushback_message(message)
			@inq.push(message)
		end
		
		def enq_message(message)
			@inq.enq(message)
		end
	
		def receive_message(message)
			enq_message(message)
		end
	end

end
