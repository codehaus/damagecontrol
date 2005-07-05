module DamageControl
  module Publisher
    module Email
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
    end
  end
end  