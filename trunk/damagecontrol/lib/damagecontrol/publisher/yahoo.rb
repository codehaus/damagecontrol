require 'rscm/annotations'
require 'damagecontrol/project'
require 'rscm/annotations'

module DamageControl
  module Publisher
    class Yahoo < Base
      register self
    
      def initialize
      end

      def name
        "Yahoo"
      end    

      def publish(build)
      end
    end
  end
end