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
          BuildResultMailer.server_settings = server_settings
          BuildResultMailer.delivery_method = delivery_method    
          
          BuildResultMailer.deliver_build_result(to.split(%r{,\s*}), from, build)
        end

      end
    end
  end
end