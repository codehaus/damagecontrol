require 'action_mailer'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Email < Base
      register self
    
      ann :description => "How to deliver email [\"sendmail\"|\"smtp\"]"
      attr_accessor :delivery_method

      ann :description => "Recipients (comma separated)"
      attr_accessor :recipients

      ann :description => "Who sends the email"
      attr_accessor :from
      
      def initialize
        @delivery_method = "sendmail"
        @recipients = ""
        @from = "\"DamageControl\" <dcontrol@codehaus.org>"
      end
      
      def name
        "Email"
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
        @recipients = email_publisher.recipients.split(%r{,\s*})

        @from = email_publisher.from

        @subject = "#{build.project.name} Build #{build.status_message}"
        @sent_on = Time.new.utc
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