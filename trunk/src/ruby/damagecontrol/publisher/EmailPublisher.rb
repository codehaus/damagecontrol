require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'ftools'

module DamageControl

  class EmailPublisher < AsyncComponent
  
    attr_writer :filesystem

    def initialize(channel, template, from, server="localhost", port=25)
      super(channel)
      @template = template
      @from = from
      @server = server
      @port = port
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        if(nag_email = message.build.config["nag_email"])
          sendmail(@template.generate(message.build), @from, nag_email)
        end
      end
    end
    
    def sendmail(content, from, to)
      session = Net::SMTP.new(@server, @port)
      session.sendmail(content, from, to)
    end
  end
end
