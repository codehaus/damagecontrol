module DamageControl
  module Publisher
    class Base < Plugin
      become_parent
      attr_accessor :enabling_states
      
      def initialize
        @enabling_states = []
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
