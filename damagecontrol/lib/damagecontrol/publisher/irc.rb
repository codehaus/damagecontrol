require 'rscm/annotations'
require 'damagecontrol/project'
require 'rscm/annotations'

module DamageControl
  module Publisher
    class Irc < Base
      register self
    
      ann :description => "IRC server"
      attr_reader :server

      ann :description => "IRC notification channel"
      attr_reader :channel

      ann :description => "DamageControl's IRC nick"
      attr_reader :nick
    
      def initialize
        @server = "irc.codehaus.org"
        @channel = "#damagecontrol"
        @nick = "dcontrol"
      end

      def name
        "IRC"
      end    

      def publish(build)
      end
    end
  end
end