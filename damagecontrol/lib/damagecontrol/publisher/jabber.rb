require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Jabber < Base
      register self
    
      def name
        "Jabber"
      end    

      def publish(build)
      end
    end
  end
end