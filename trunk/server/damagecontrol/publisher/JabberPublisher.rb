require 'erb'
require 'jabber4r/jabber4r'
require 'damagecontrol/core/AsyncComponent'
require 'damagecontrol/core/BuildEvents'

module DamageControl

  class JabberPublisher < AsyncComponent
  
    attr_accessor :jabber
    attr_reader :channel
    attr_reader :recipients
  
    def initialize(channel, publisherJabberAccountUser, publisherJabberAccountPassword, recipients, template)
      super(channel)
      @jabber = JabberConnection.new(publisherJabberAccountUser, publisherJabberAccountPassword)
      @recipients = recipients

      template_dir = "#{File.expand_path(File.dirname(__FILE__))}/../template"
      @template = File.new("#{template_dir}/#{template}").read
    end
  
    def process_message(message)
      if message.is_a?(BuildCompleteEvent)
        build = message.build
        msg = ERB.new(@template).result(binding)
        @recipients.each{|recipient|
          @jabber.send_message_to_recipient(recipient, msg)
        }
      end

      if message.is_a?(UserMessage)
        @irc.send_message_to_channel(message.message)
      end
    end
  end
  
  class JabberConnection
    attr_reader :publisherJabberAccountUser
    attr_reader :publisherJabberAccountPassword
  
    def initialize(publisherJabberAccountUser, publisherJabberAccountPassword)
      @publisherJabberAccountUser = publisherJabberAccountUser
      @publisherJabberAccountPassword = publisherJabberAccountPassword
    end
  
    def send_message_to_recipient(recipient, content)
      session = Jabber::Session.bind(@publisherJabberAccountUser, @publisherJabberAccountPassword)
      session.new_message(recipient).set_subject('DamageControl build message').set_body(content).send
    rescue Exception=>error
      puts error
    ensure
      session.release if session
    end   
  end

end

