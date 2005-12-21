module MetaProject
  module Tracker
    class Base
      attr_accessor :enabled

      def category
        "tracker"
      end

      def exclusive?
        true
      end
    end
    
    class NullTracker < Base
      def markup(message)
        message
      end
    end

  end
end