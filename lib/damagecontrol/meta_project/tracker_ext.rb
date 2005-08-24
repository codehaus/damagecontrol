module MetaProject
  module Tracker
  
    # Tracker objects are responsible for interacting with issue trackers (bug trackers).
    # They know how to recognise issue identifiers in strings (typically from SCM commit
    # messages) and turn these into HTML links that point to the associated issue on an
    # issue tracker installation running somewhere else.
    class Base
      include ::DamageControl::Dom

      attr_accessor :enabled

      def category
        "tracker"
      end

      def exclusive?
        true
      end
    end

  end
end