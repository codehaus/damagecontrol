require 'rscm/annotations'
require 'damagecontrol/project'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Growl < Base
      register self
    
      ann :description => "Hosts", :tip => "(OS X) hosts that will receive Growl notifications"
      attr_reader :hosts

      def initialize
        @hosts = "localhost"
      end

      def name
        "Growl"
      end    

      def publish(build)
      end
    end
  end
end