require 'action_mailer'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Sendmail < AbstractEmail
      register self
    
      def name
        "Sendmail"
      end
    
      def delivery_method
        "sendmail"
      end

      def server_settings
        {}
      end
    end

    class Email < Sendmail
      # for BWC only
    end
  end
end  