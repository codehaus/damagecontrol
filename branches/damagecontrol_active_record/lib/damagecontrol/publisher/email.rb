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
        @from = "dcontrol@damagecontrol.buildpatterns.com"

        @server = ""
        @port = ""
        @domain = ""
        @user_name = ""
        @password = ""
        @authentication = ""
      end

      def publish(build)
        @stdout_tail = build.tail(build.stdout_file)
        @stderr_tail = build.tail(build.stderr_file)
        template = ERB.new(File.read(RAILS_ROOT + '/app/views/build_result_mailer/build_result.rhtml'))
        @headline = BuildResultMailer.headline(build)
        @build = build
        b = binding
        @body = template.result(b)        
        
        if(delivery_method == "GMail")
          GMailer.connect(@gmail_user, @password) do |g|
            # 'From' default gmail.com account
            g.send(
              :to => to.split(%r{,\s*}).join(","),
              :subject => @headline,
              :body => @body,
              :html => true # Relies on my patch: http://rubyforge.org/tracker/index.php?group_id=869&atid=3435
            )
          end
        else
          BuildResultMailer.delivery_method = delivery_method
          BuildResultMailer.server_settings = server_settings
          BuildResultMailer.deliver_build_result(to.split(%r{,\s*}), from, build, @stdout_tail, @stderr_tail)
        end
        # The only reason to return something here is to display some info to the user if called
        # via the controller.
        return "Sent email (via #{delivery_details}) to [#{@to}] with subject '#{@headline}' and body:<br/>#{@body}"
      end

    private
    
      def delivery_details
        "#{delivery_method}, #{server_settings.inspect}"
      end
    
      def delivery_method
        if(@from =~ /(.*)@gmail.com/)
          @gmail_user = $1
          "GMail"
        else
          @server != "" ? "smtp" : "sendmail"
        end
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
