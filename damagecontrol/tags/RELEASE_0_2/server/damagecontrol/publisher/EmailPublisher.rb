require 'erb'
require 'net/smtp'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/AsyncComponent'

module DamageControl

  class EmailPublisher < AsyncComponent

    attr_reader :always_mail
    
    def initialize(channel, dc_server, subject_template, body_template, from, always_mail=false, mail_server="localhost", port=25)
      super(channel)
      @dc_server = dc_server
      template_dir = "#{File.expand_path(File.dirname(__FILE__))}/../template"
      @subject_template = File.new("#{template_dir}/#{subject_template}").read
      @body_template = File.new("#{template_dir}/#{body_template}").read
      @from = from
      @always_mail = always_mail
      @mail_server = mail_server
      @port = port
    end
  
    def process_message(message)
      if message.is_a? BuildCompleteEvent
        if((Build::FAILED == message.build.status) || always_mail)
          if(nag_email = message.build.config["nag_email"])
            build = message.build
            dc_url = @dc_server.dc_url
            subject = ERB.new(@subject_template).result(binding)
            body    = ERB.new(@body_template).result(binding)
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
             "Content-Type: text/html\r\n" +
             "\r\n" +
             body
      begin
        logger.info("sending email to #{to} using SMTP server #{@mail_server}")
        Net::SMTP.start(@mail_server) do |smtp|
          smtp.sendmail( mail, from, to )
        end
      rescue => e
        puts "Couldn't send mail:" + e.message
        puts e.backtrace.join("\n")
      end
    end
  end
end

if __FILE__ == $0
  ep = DamageControl::EmailPublisher.new(nil, "short_text_build_result.erb", "short_text_build_result.erb")
end