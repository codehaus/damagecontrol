module DamageControl
  module Publisher
    module Email
      class Smtp < AbstractEmail
        register self
    
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

        def initialize
          super
          @server = "localhost"
          @port = 25
          @domain = "localhost.localdomain"
        end

        def name
          "SMTP"
        end
    
        def delivery_method
          "smtp"
        end

        def server_settings
          {
            :server => @server,
            :port => @port.to_i,
            :domain => @domain,
            :user_name => @user_name,
            :password => @password,
            :authentication => @authentication
          }
        end
      end
    end
  end
end  