require 'rscm/path_converter'
require 'rscm/annotations'

module DamageControl
  module Tracker

    # Simple superclass so we can easily include mixins
    # for all subclasses in one fell swoop.
    class Base #:nodoc:
      @@classes = []
      def self.register(cls) 
        @@classes << cls unless @@classes.index(cls)
      end
      
      def self.classes
        @@classes
      end

      def htmlize(str)
        str.gsub(/\n/, "<br/>")
      end
    end

    class None < Base
      register self
    
      def name
        "No Tracker"
      end

      def highlight(s)
        htmlize(s)
      end

      def url
        "#"
      end
    end
    
  end
end
