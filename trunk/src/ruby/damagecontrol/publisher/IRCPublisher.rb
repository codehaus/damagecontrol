$:<<"../../lib/rica"

require 'rica'
require 'damagecontrol/Timer'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Logging'

module DamageControl

  class IRCPublisher < AsyncComponent

    include Logging
  
    attr_accessor :irc
    attr_accessor :handle
    attr_reader :channel
    attr_reader :server
  
    def initialize(channel, server, irc_channel, template)
      super(channel)
      @irc = IRCConnection.new()
      @server = server
      @irc_channel = irc_channel
      @template = template
      @handle = 'dcontrol'
    end
  
    def process_message(message)
      if message.is_a?(BuildCompleteEvent)
        if @irc.connected? && @irc.in_channel?
          content = @template.generate(message.build)
          logger.info("sending irc message #{content}")
          @irc.send_message_to_channel(content)
        else
          logger.info("connecting to #{server} and joining #{@server_channel}")
          @irc.connect(server, handle) unless @irc.connected?
          @irc.join_channel(@irc_channel) if @irc.connected? && !@irc.in_channel?
          raise "not in channel yet"
        end
      end
    end
  end

  # Simplification on top of Rica, supports one channel at the same time only
  class IRCConnection < Rica::MessageProcessor
    
    def on_link_established(msg)
      @current_server=msg.server
      @current_channel=nil
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
  
    def connect(server, handle)
      self.open(server,['damagecontrol','DamageControl'], handle)
    end

  end
end

