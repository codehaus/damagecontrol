require 'rscm/annotations'
require 'damagecontrol/project'
require 'rscm/annotations'

module DamageControl
  module Publisher
    class Execute < Base
      register self
    
      def initialize
      end

      def name
        "Execute"
      end    

      def publish(build)
      end
    end
  end
end