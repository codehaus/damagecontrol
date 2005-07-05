require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Execute < Base
      #register self
    
      def name
        "FTP"
      end    

      def publish(build)
      end
    end
  end
end