$damagecontrol_home = '../..'
$:<<"#{$damagecontrol_home}/lib/rica"
$:<<"#{$damagecontrol_home}/src/ruby"

require 'damagecontrol/CruiseControlLogPoller'
require 'rica'

include DamageControl

logdir = "logs"

hub = Hub.new
CruiseControlLogPoller.new(logdir, hub).start

class IRCPublisher < Rica::MessageProcessor

	def initialize(hub)
		super()
		hub.add_subscriber(self)
		@channel = "#build"
	end
	
	def default_action(msg)
		puts(msg.string("%T %s %t:%f %C %a"))
	end

	def on_link_established(msg)
		@current_server=msg.server
		@current_channel=nil
		puts(msg.string("%T %s Link Established"))
	end

	#
	# auto join
	#
	def on_recv_rpl_motd(msg)
		if(@current_channel.nil?)
			@current_server=msg.server
			cmnd_join(msg.server, @channel)
		end
	end
	
	#
	# respond to join
	#
	def on_recv_cmnd_join(msg)
		@current_channel=msg.to
	end
	
	def connected?
		!@current_server.nil? && !@current_channel.nil?
	end

	def receive_message(message)
		if (connected? && message.is_a?(BuildCompleteEvent))
			cmnd_privmsg(@current_server, \
				@current_channel, \
				"BUILD COMPLETE #{message.project.name}")
		end
	end
end
IRCPublisher.new(hub).open('irc.codehaus.org',['damagecontrol','DamageControl Example'],'dcontrol')

# sleep until ctrl-c
sleep