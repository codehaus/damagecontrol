require 'rscm/annotations'
require 'damagecontrol/project'
require 'rscm/annotations'

module DamageControl
  module Publisher
    class Jabber < Base
      register self
    
      def initialize
      end

      def name
        "Jabber"
      end    

      def publish(build)
      end
    end
  end
end