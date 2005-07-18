module DamageControl
  module Tracker
    class Bugzilla < Base
      register self

      ann :description => "Bugzilla URL"
      ann :tip => "The URL of the Bugzilla installation."
      attr_accessor :url

      def self.identifier_examples
        ["#5", "#239"]
      end

      def initialize
        @url = "http://bugzilla.org/"
      end
      
      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(@url)
        if (url)
          htmlize(s.gsub(/#([0-9]+)/, "<a href=\"#{url}show_bug.cgi?id=\\1\">#\\1</a>"))
        else
          htmlize(s)
        end
      end
    end
  end
end