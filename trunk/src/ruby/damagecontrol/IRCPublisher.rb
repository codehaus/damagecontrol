$:<<"../../lib/rica"

require 'rica'

require 'damagecontrol/Timer'
require 'damagecontrol/FileUtils'

module DamageControl

	# Simplification on top of Rica, supports one channel at the same time only
	class IRCConnection < Rica::MessageProcessor
		
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

		def join_channel(channel)
			if(!in_channel?)
				cmnd_join(@current_server, channel)
			end
		end

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
			cmnd_privmsg(@current_server, @current_channel, message)
		end
	
		def connect(server)
			self.open(server,['damagecontrol','DamageControl'],'dcontrol')
		end

	end

	class AsyncComponent
		include TimerMixin
		
		def initialize(hub)
			super()
			@inq = []
			hub.add_subscriber(self)
		end

		def tick(time)
			schedule_next_tick
			process_messages
		end
		
		def process_messages
			# process copy of array so that process_message can remove entries via consume
			@inq.clone.each {|message| process_message(message) }
		end

		def consume_message(message)
			@inq.delete(message)
		end
		
		def enq_message(message)
			@inq.push(message)
		end
	
		def receive_message(message)
			enq_message(message)
		end
		
		def consumed_message?(message)
			!@inq.index(message)
		end
	end

	class IRCPublisher < AsyncComponent
	
		attr_accessor :irc
	
		def initialize(hub, server, channel)
			super(hub)
			@irc = IRCConnection.new()
			@server = server
			@channel = channel
		end
	
		def process_message(message)
			if message.is_a?(BuildCompleteEvent)
				if @irc.connected? && @irc.in_channel?
					@irc.send_message_to_channel("BUILD COMPLETE, project: #{message.project.name} label: #{message.build.label}")
					consume_message(message)
				else
					@irc.connect(@server) unless @irc.connected?
					@irc.join_channel(@channel) if @irc.connected? && !@irc.in_channel?
				end
			end
		end

	end

end
