$:<<"../../lib/rica"

require 'rica'
require 'damagecontrol/Timer'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildEvents'

module DamageControl

  class IRCPublisher < AsyncComponent
  
    attr_accessor :irc
    attr_accessor :handle
    attr_reader :channel
    attr_reader :server
  
    def initialize(hub, server, channel, template)
      super(hub)
      @irc = IRCConnection.new()
      @server = server
      @channel = channel
      @template = template
      @handle = "dcontrol"
    end
  
    def process_message(event)
      puts "MESSAGE!!!!!!!!!!!!"
      if event.is_a? BuildCompleteEvent
        puts "POSTING!!!!!!!!!!!!"
        post_irc_message(event.build)
        puts "CONSUMING!!!!!!!!!!!!"
      end
    end

  private

    def post_irc_message(build_result)
      @irc.connect(server, handle) unless @irc.connected?
      @irc.join_channel(channel) if @irc.connected? && !@irc.in_channel?
      @irc.send_message_to_channel(@template.generate(build_result))
    end

  end

  # Simplification on top of Rica, supports one channel at the same time only
  class IRCConnection < Rica::MessageProcessor
    
    def connect(server, handle)
      self.open(server,['damagecontrol','DamageControl'], handle)
    end

    def join_channel(channel)
      if(!in_channel?)
        cmnd_join(@current_server, channel)
      end
    end

    def send_message_to_channel(message)
      cmnd_privmsg(@current_server, @current_channel, message)
    end
  
    def connected?
      !@current_server.nil?
    end

    def in_channel?
      !@current_channel.nil?
    end
    
    # callbacks

    def on_link_established(msg)
      @current_server=msg.server
      @current_channel=nil
    end

    def on_link_closed(msg)
      @current_server=nil
      @current_channel=nil
    end

    def on_recv_cmnd_join(msg)
      @current_channel=msg.to
    end
    
  end

end
