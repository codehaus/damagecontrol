require 'erb'
require 'rica/rica'
require 'damagecontrol/util/Timer'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'

module DamageControl

  class IRCPublisher < AsyncComponent

    include Logging
  
    attr_reader :channel
    attr_reader :server
    attr_accessor :irc
    attr_accessor :handle
    attr_accessor :send_message_on_build_request
  
    def initialize(channel, dc_server, irc_server, irc_channel, template)
      super(channel)
      @dc_server = dc_server
      @irc = IRCConnection.new
      @irc_server = irc_server
      @irc_channel = irc_channel
      @template = template
      @handle = 'dcontrol'
      @send_message_on_build_request = true

      template_dir = "#{File.expand_path(File.dirname(__FILE__))}/../template"
      @template = File.new("#{template_dir}/#{template}").read
    end
    
    def start
      super
      ensure_in_channel
    end
    
    def wait_until(timeout=nil)
      time_waited = 0
      while !yield
        sleep 1
        time_waited += 1
        raise "time out" if(!timeout.nil? && time_waited > timeout)
      end
    end
    
    def ensure_in_channel
      if !@irc.connected?
        logger.info("connecting to #{irc_server}")
        @irc.connect(irc_server, handle)
        wait_until(10) { @irc.connected? }
      end
      
      if @irc.connected? && !@irc.in_channel?
        logger.info("joining channel #{@irc_channel}")
        @irc.join_channel(@irc_channel)
        wait_until(10) { @irc.in_channel? }
      end
    end
    
    def format_changeset(changeset)
      message_to_modifications = {}
      changeset.each {|m| message_to_modifications[m.message + m.developer] = []}
      changeset.each {|m| message_to_modifications[m.message + m.developer]<<m}
      result = message_to_modifications.collect do |key, modifications|
        files = modifications.collect{|m| m.path}.join(", ")
        "\"#{modifications[0].message}\" by #{modifications[0].developer}: #{files}"
      end
      result.sort
    end
  
    def process_message(message)
      ensure_in_channel
      
      if send_message_on_build_request && message.is_a?(BuildRequestEvent)
        @irc.send_message_to_channel("[#{message.build.project_name}] BUILD REQUESTED")
      end
      
      if message.is_a?(BuildStartedEvent)
        @irc.send_message_to_channel("[#{message.build.project_name}] BUILD STARTED")
        format_changeset(message.build.modification_set).each do |change|
          @irc.send_message_to_channel("[#{message.build.project_name}] #{change}")
        end
      end
      
      if message.is_a?(BuildCompleteEvent)
        build = message.build
        dc_url = @dc_server.dc_url
        msg = ERB.new(@template).result(binding)
        @irc.send_message_to_channel(msg)
      end

      if message.is_a?(UserMessage)
        @irc.send_message_to_channel(message.message)
      end
    end
  end

  # Simplification on top of Rica, supports one channel at the same time only
  class IRCConnection < Rica::MessageProcessor
    
    include Logging
    
    def default_action(msg)
      logger.debug(msg) if logger.debug?
    end

    def on_link_established(msg)
      @current_server=msg.server
      @current_channel=nil
      
      logger.info("connected to #{@current_server}")
    end

    def on_link_closed(msg)
      logger.info("link closed to #{@current_server}")
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
      logger.info("joined channel #{@current_channel}")
    end
    
    def connected?
      !@current_server.nil?
    end

    def in_channel?
      !@current_channel.nil?
    end
    
    def send_message_to_channel(message)
      logger.info("sending irc message #{message}")
      cmnd_privmsg(@current_server, @current_channel, message)
    end
  
    def connect(server, handle)
      self.open(server,['damagecontrol','DamageControl'], handle)
    end

  end
end

