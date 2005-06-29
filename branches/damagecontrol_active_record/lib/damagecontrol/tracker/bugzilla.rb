module DamageControl
  module Tracker
    class Bugzilla < Base
      register self

      ann :description => "Bugzilla URL", :tip => "The URL of the Bugzilla installation."
      attr_accessor :url

      def initialize(url="http://bugzilla.org/")
        @url = url
      end
      
      def name
        "Bugzilla"
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