require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/AsyncComponent'
require 'net/smtp'

module DamageControl

  class EmailPublisher < AsyncComponent

    attr_reader :always_mail

  
    def initialize(channel, subject_template, body_template, from, always_mail=false, server="localhost", port=25)
      super(channel)
      @subject_template = subject_template
      @body_template = body_template
      @from = from
      @always_mail = always_mail
      @server = server
      @port = port
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        if((Build::FAILED == message.build.status) || always_mail)
          if(nag_email = message.build.config["nag_email"])
            subject = @subject_template.generate(message.build)
            body = @body_template.generate(message.build)
            sendmail(subject, body, @from, nag_email)
          end
        end
      end
    end
    
    def sendmail(subject, body, from, to)
      mail = "To: #{to}\r\n" +
             "From: #{from}\r\n" +
             "Subject: #{subject}\r\n" +
             "MIME-Version: 1.0\r\n" +
             "Content-Type: text/html\r\n" 
             "\r\n" +
             body
      begin
        logger.info("sending email to #{to} using SMTP server #{@server}")
        Net::SMTP.start(@server) do |smtp|
          smtp.sendmail( mail, from, to )
        end
      rescue => e
        puts "Couldn't send mail:" + e.message
        puts e.backtrace.join("\n")
      end
    end
  end
end