require 'erb'
require 'net/smtp'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/Logging'
require 'pebbles/Space'

module DamageControl

  class EmailPublisher < Pebbles::Space

    include Logging

    attr_accessor :subject_template
    attr_accessor :body_template
    attr_accessor :from
    attr_accessor :mail_server
    attr_accessor :port
    attr_accessor :always_mail
    
    def initialize(channel, build_history_repository, config = {})
      super
      channel.add_consumer(self)
      @build_history_repository = build_history_repository
      template_dir = "#{File.expand_path(File.dirname(__FILE__))}/../template"
      subject_template_file = config[:SubjectTemplate] || required_config(:SubjectTemplate)
      @subject_template = File.new("#{template_dir}/#{subject_template_file}").read
      body_template_file = config[:BodyTemplate] || required_config(:BodyTemplate)
      @body_template = File.new("#{template_dir}/#{body_template_file}").read
      @from = config[:FromEmail] || required_config(:FromEmail)
      @always_mail = config[:SendEmailOnAllBuilds] || false
      @mail_server = config[:MailServerHost] || "localhost"
      @port = config[:MailServerPort] || 25
      @sender = config[:Sender] || Net::SMTP      
    end
    
    def required_config(key)
      raise "required config parameter #{key}"
    end
  
    def on_message(message)
      if message.is_a? BuildCompleteEvent
        if((Build::FAILED == message.build.status) || always_mail)
          if(nag_email = message.build.config["nag_email"])
            build = message.build
            subject = ERB.new(@subject_template).result(binding)
            body    = ERB.new(@body_template).result(binding)
            sendmail(subject, build.dc_start_time, body, @from, nag_email)
          end
        end
      end
    end
    
    def sendmail(subject, date, body, from, to)
      # convert separators to spaces, according to the SMTP protocol.
      to.gsub(',',' ').gsub(';',' ')
      mail = "To: #{to}\r\n" +
             "From: #{from}\r\n" +
             "Date: " + date.to_rfc2822 + "\r\n" +
             "Subject: #{subject}\r\n" +
             "MIME-Version: 1.0\r\n" +
             "Content-Type: text/html\r\n" +
             "\r\n" +
             body
      begin
        logger.info("sending email to #{to} using SMTP server #{@mail_server}")
        @sender.start(@mail_server) do |smtp|
          # convert space separated string to array
          smtp.sendmail( mail, from, to.split )
        end
      rescue => e
        puts "Couldn't send mail:" + e.message
        puts e.backtrace.join("\n")
      end
    end
    
    def stdout?
      File.exist?(@build_history_repository.stdout_file(build.project_name, build.dc_creation_time))
    end

    def stderr?
      File.exist?(@build_history_repository.stdout_file(build.project_name, build.dc_creation_time))
    end
  end
end
