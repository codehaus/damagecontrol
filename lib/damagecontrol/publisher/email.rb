require 'gmailer'

module DamageControl
  module Publisher
    # Uses sendmail, smtp or gmail to send email. Which one to use depends on attributes.
    class Email < Base
      attr_accessor :to
      attr_accessor :from           # will use gmailer if this is a gmail address

      attr_accessor :server         # setting this will use smtp unless we're using gmail
      attr_accessor :port           # will default to 25 if empty
      attr_accessor :domain         # will default to "localhost.localdomain" if empty
      attr_accessor :user_name      # if all of these are empty strings,
      attr_accessor :password       # no authentication will be used
      attr_accessor :authentication # (all fields will be set to nil)

      def initialize
        @content_type = "text/html"
        @to = ""
        @from = "\"DamageControl\" <dcontrol@damagecontrol.buildpatterns.org>"

        # SMTP only
        @server = ""
        @port = ""
        @domain = ""
        @user_name = ""
        @password = ""
        @authentication = ""
      end

      def publish(build)
        if(@from =~ /(.*)@gmail.com/)
          GMailer.connect($1, @password) do |g|
            # 'From' default gmail.com account
            g.send(
              :to => to.split(%r{,\s*}).join(","),
              :subject => "#{build.project.name}: #{build.state.class.name}",
              :body => "Hello"
            )
          end
        else
          BuildResultMailer.delivery_method = delivery_method
          BuildResultMailer.server_settings = server_settings
          BuildResultMailer.deliver_build_result(to.split(%r{,\s*}), from, build)
        end
      end

    private
    
      def delivery_method
        (@server && @server.strip != "") ? "smtp" : "sendmail"
      end

      def server_settings
        if(delivery_method == "smtp")
          non_authenticated = @user_name == "" && @password == "" && @authentication == ""
          {
            :server         => @server,
            :port           => @port   == "" ? 25 : @port.to_i,
            :domain         => @domain == "" ? "localhost.localdomain" : @domain,
            :user_name      => non_authenticated ? nil : @user_name,
            :password       => non_authenticated ? nil : @password,
            :authentication => non_authenticated ? nil : @authentication
          }
        else
          {}
        end
      end
    end
  end
end