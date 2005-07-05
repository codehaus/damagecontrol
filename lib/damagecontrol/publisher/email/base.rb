module DamageControl
  module Publisher
    module Email
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
          BuildMailer.server_settings = server_settings
          BuildMailer.delivery_method = delivery_method      
          BuildMailer.deliver_email(build, self)
        end

      end

      class BuildMailer < ActionMailer::Base
        self.template_root = File.dirname(__FILE__)

        def email(build, email_publisher, foo=nil, bar=nil)
          @delivery_method = email_publisher.delivery_method
          @recipients = email_publisher.to.split(%r{,\s*})
          @from = email_publisher.from
          @subject = "#{build.revision.project.name} Build #{build.state.description}"
          @sent_on = Time.new.utc
          @headers['Content-Type'] = "text/html"
          @body["build"] = build

          logger.info("Sending email to #{email_publisher.to.inspect} via #{@delivery_method}") if logger
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
end