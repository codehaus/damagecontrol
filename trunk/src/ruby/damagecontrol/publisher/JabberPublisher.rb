$:<<"../../lib/jabber4r"

require 'jabber4r/jabber4r'
require 'damagecontrol/Timer'
require 'damagecontrol/AsyncComponent'
require 'damagecontrol/BuildEvents'

module DamageControl

  class JabberPublisher < AsyncComponent
  
    attr_accessor :jabber
    attr_reader :channel
    attr_reader :recipients
  
    def initialize(channel, publisherJabberAccountUser, publisherJabberAccountPassword, recipients, template)
      super(channel)
      @jabber = JabberConnection.new(publisherJabberAccountUser, publisherJabberAccountPassword)
	  @recipients = recipients
      @template = template
    end
  
    def process_message(message)
      if message.is_a?(BuildCompleteEvent)
          content = @template.generate(message.build)
		  @recipients.each{|recipient|
            @jabber.send_message_to_recipient(recipient, content)
		  }
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

