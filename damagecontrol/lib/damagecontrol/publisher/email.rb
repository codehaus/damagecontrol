require 'rubygems'
require_gem 'actionmailer'
require 'action_mailer'
require 'damagecontrol/project'

module DamageControl
  module Publisher
    class Email
      # Register ourself
      Project.available_publisher_classes << self
    
      attr_accessor :delivery_method
      attr_accessor :recipients
      attr_accessor :from
      
      def initialize
        @delivery_method = "sendmail"
        @recipients = []
        @from = "dcontrol@codehaus.org"
      end
    
      def publish(build)
        BuildMailer.template_root = File.expand_path(File.dirname(__FILE__) + "/../../../app/views")
        BuildMailer.delivery_method = @delivery_method      
        BuildMailer.deliver_email(build, self)
      end
    end

    class BuildMailer < ActionMailer::Base
      def email(build, email_publisher)
        Log.info("Sending email to #{email_publisher.recipients.inspect}")
        @delivery_method = email_publisher.delivery_method
        @recipients = email_publisher.recipients
        @from = email_publisher.from

        @subject      = "#{build.project.name} build failed"
        @sent_on      = Time.new.utc
        @body["build"] = build
      end
      
      # We have to define this, since our name is used to find the email template
      class << self
        def to_s
          "Build"
        end        
      end
    end
  end
end