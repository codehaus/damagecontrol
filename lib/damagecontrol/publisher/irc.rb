require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class Irc < Base
      attr_reader :server
      attr_reader :channel
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