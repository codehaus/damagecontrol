module DamageControl
  module Publisher
    class Base < Plugin
      become_parent
      attr_accessor :enabling_states
      
      def initialize
        @enabling_states = []
      end
      
      def enabled
        @enabling_states && !@enabling_states.empty?
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

      def category
        "publisher"
      end

      def exclusive?
        false
      end

      # Exclude default rendering of enabling_states. It's handled by the _publisher.rhtml
      # template.
      def default_render_excludes
        [:enabling_states, :fileutils_label, :fileutils_output]
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].each do |src|
  require src unless src == __FILE__
end
