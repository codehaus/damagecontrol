module DamageControl
  module Importer
    class Import
      include Dom
      
      def enabled
        true
      end

      def category
        "project"
      end

      def exclusive?
        false
      end
    end
  end
end