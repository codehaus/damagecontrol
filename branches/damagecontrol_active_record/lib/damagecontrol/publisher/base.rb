module DamageControl
  module Publisher
    class Base
      include Dom

      def self.classes
        [
          #AmbientOrb,
          ArtifactArchiver,
          #BuildDuration,
          Email,
          #Execute,
          Growl,
          #Irc,
          Jabber,
          Sound
          #X10Cm11A,
          #X10Cm17A,
          #Yahoo
        ]
      end

      attr_accessor :enabling_states
      
      def initialize
        @enabling_states = []
      end
      
      def enabled
        @enabling_states && !@enabling_states.empty?
      end
      
      def category
        "publisher"
      end

      def exclusive?
        false
      end

      # Publishes +build+ if its state is
      # among our +enabling_states+.
      def publish_maybe(build)
        es = @enabling_states || []
        state_classes = es.collect do |state| 
          state.class
        end
        should_publish = state_classes.index(build.state.class)
        if(should_publish)
          publish(build)
        end
      end

    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].each do |src|
  require src unless src == __FILE__
end
