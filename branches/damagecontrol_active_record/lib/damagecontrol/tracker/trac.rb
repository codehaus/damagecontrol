module DamageControl
  module Tracker
    class Trac < Base
      register self

      def self.identifier_examples
        ["#5", "#239"]
      end

      ann :description => "Trac URL"
      ann :tip => "The URL of the Trac installation. This URL should include no trailing slash. Example: http://my.trac.home/cgi-bin/trac.cgi"
      attr_accessor :url

      def initialize
        # TODO: point to their own one
        @url = "http://www.edgewall.com/trac"
      end
      
      def name
        "Trac"
      end

      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(@url)
        if (url)
          htmlize(s.gsub(/#([0-9]+)/, "<a href=\"#{url}/ticket/\\1\">#\\1</a>"))
        else
          htmlize(s)
        end
      end
    end

  end
end