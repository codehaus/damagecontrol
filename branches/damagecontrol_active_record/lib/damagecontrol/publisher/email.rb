module DamageControl
  module Publisher
    class Email < Base
      attr_accessor :enabled

      ann :tip => "Specify as many email addresses as you like, separated with comma or whitespace."
      ann :description => "To"
      attr_accessor :to

      ann :tip => "Who the emails should appear to be from."
      ann :description => "From"
      attr_accessor :from

      # SMTP only settings

      ann :tip => "SMTP server's IP address or name."
      ann :description => "Server"
      attr_accessor :server

      ann :tip => "SMTP server's port."
      ann :description => "Port"
      attr_accessor :port

      ann :tip => "If you need to specify a HELO domain, you can do it here."
      ann :description => "Domain"
      attr_accessor :domain

      ann :tip => "If your SMTP server requires authentication, set the username."
      ann :description => "User name"
      attr_accessor :user_name

      ann :tip => "If your SMTP server requires authentication, set the password."
      ann :description => "Password"
      attr_accessor :password

      ann :tip => "If your SMTP server requires authentication, you need to specify " +
                  "the authentication type here. This is one of 'plain', 'login', 'cram_md5'"
      ann :description => "Authentication"
      attr_accessor :authentication

      ann :description => "smtp or sendmail"
      attr_accessor :delivery_method

      def initialize
        @to = ""
        @from = "\"DamageControl\" <dcontrol@codehaus.org>"
        @delivery_method = "smtp"

        # SMTP only
        @server = "localhost"
        @port = 25
        @domain = "localhost.localdomain"
      end

      def publish(build)
        BuildResultMailer.server_settings = server_settings
        BuildResultMailer.delivery_method = @delivery_method    

        BuildResultMailer.deliver_build_result(to.split(%r{,\s*}), from, build)
      end

    private

      def server_settings
        if(@delivery_method == "smtp")
          {
            :server => @server,
            :port => @port.to_i,
            :domain => @domain,
            :user_name => @user_name,
            :password => @password,
            :authentication => @authentication
          }
        else
          {}
        end
      end
    end
  end
end