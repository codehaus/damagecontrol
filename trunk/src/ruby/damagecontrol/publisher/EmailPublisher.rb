require 'damagecontrol/BuildEvents'
require 'damagecontrol/AsyncComponent'
require 'net/smtp'

module DamageControl

  class EmailPublisher < AsyncComponent
  
    def initialize(channel, subject_template, body_template, from, server="localhost", port=25)
      super(channel)
      @subject_template = subject_template
      @body_template = body_template
      @from = from
      @server = server
      @port = port
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        if(nag_email = message.build.config["nag_email"])
          subject = @subject_template.generate(message.build)
          body = @body_template.generate(message.build)
          sendmail(subject, body, @from, nag_email)
        end
      end
    end
    
    def sendmail(subject, body, from, to)
      mail = "To: #{to}\r\n" +
             "From: #{from}\r\n" +
             "Subject: #{subject}\r\n" +
             "\r\n" +
             body
      begin
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
