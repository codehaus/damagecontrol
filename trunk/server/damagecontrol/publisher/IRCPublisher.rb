require 'erb'
require 'rica/rica'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'
require 'pebbles/MVCServlet'

module DamageControl

  class IRCPublisher < AsyncComponent

    include Logging
    include Pebbles::SimpleERB
  
    attr_reader :channel
    attr_reader :irc_server
    attr_accessor :irc
    attr_accessor :handle
    attr_accessor :send_message_on_build_request
  
    def initialize(channel, irc_server, irc_channel, template)
      super(channel)
      @irc = IRCConnection.new
      @irc_server = irc_server
      @irc_channel = irc_channel
      @template = template
      @handle = 'dcontrol'
      @send_message_on_build_request = true
      @template = template
    end
    
    def template_dir
      "#{File.expand_path(File.dirname(__FILE__))}/../template"
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
  
    def process_message(message)
      ensure_in_channel
      
      if (message.is_a?(BuildEvent))
        build = message.build
        
        if send_message_on_build_request && message.is_a?(BuildRequestEvent)
          @irc.send_message_to_channel("#{prefix(message)} BUILD REQUESTED")
        end
        
        if message.is_a?(BuildStartedEvent)
          url = if build.url then ": #{build.url}" else "" end
          @irc.send_message_to_channel("#{prefix(message)} BUILD STARTED#{url}")
          build.changesets.each do |changeset|
            @irc.send_message_to_channel("#{prefix(message)} (by #{changeset.developer} #{changeset.time_difference} ago) : #{changeset.message}")
            changeset.each do |change|
              @irc.send_message_to_channel("#{prefix(message)} #{change.path} #{change.revision}")
            end
          end
        end
        
        if message.is_a?(BuildCompleteEvent)
          msg = erb(@template, binding)
          @irc.send_message_to_channel(msg)
        end
      end

      if message.is_a?(UserMessage)
        @irc.send_message_to_channel(message.message)
      end
    end
    
    def prefix(message)
      "[#{message.build.project_name}]"
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

