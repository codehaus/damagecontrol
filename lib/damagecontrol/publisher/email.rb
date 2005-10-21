require 'gmailer'

module DamageControl
  module Publisher
    # Uses sendmail, smtp or gmail to send email. Which one to use depends on attributes.
    class Email < Base
      attr_accessor :to
      attr_accessor :from # will use gmailer if this is a gmail address

      # SMTP only settings
      attr_accessor :server # setting this will use smtp
      attr_accessor :port
      attr_accessor :domain
      attr_accessor :user_name
      attr_accessor :password
      attr_accessor :authentication

      def initialize
        @content_type = "text/html"
        @to = ""
        @from = "\"DamageControl\" <dcontrol@codehaus.org>"

        # SMTP only
        @port = 25
        @domain = "localhost.localdomain"
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