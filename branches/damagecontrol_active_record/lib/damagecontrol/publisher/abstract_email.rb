require 'action_mailer'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class AbstractEmail < Base
      attr_accessor :enabled

      ann :tip => "Specify as many email addresses as you like, separated with comma or whitespace."
      ann :description => "To"
      attr_accessor :to

      ann :tip => "Who the emails should appear to be from."
      ann :description => "From"
      attr_accessor :from
      
      def initialize
        @to = ""
        @from = "\"DamageControl\" <dcontrol@codehaus.org>"
      end
      
      def publish(build)
        BuildMailer.template_root = File.expand_path(File.dirname(__FILE__) + "/../../../app/views")
        BuildMailer.server_settings = server_settings
        BuildMailer.delivery_method = delivery_method      
        BuildMailer.deliver_email(build, self)
      end

    end

    class BuildMailer < ActionMailer::Base
      def email(build, email_publisher, foo=nil, bar=nil)
        @delivery_method = email_publisher.delivery_method
        Log.info("Sending email to #{email_publisher.to.inspect} via #{@delivery_method}")
        @recipients = email_publisher.to.split(%r{,\s*})

        @from = email_publisher.from

        @subject = "#{build.revision.project.name} Build #{build.status_message}"
        @sent_on = Time.new.utc
        @headers['Content-Type'] = "text/html"
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