require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Yahoo < Base
      register self
    
      def name
        "Yahoo"
      end    

      def publish(build)
      end
    end
  end
end