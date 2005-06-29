module DamageControl
  module Tracker
    class Trac < Base
      register self

      ann :description => "Trac URL", :tip => "The URL of the Trac installation. This URL should include no trailing slash. Example: http://my.trac.home/cgi-bin/trac.cgi"
      attr_accessor :url

      def initialize(url="http://www.edgewall.com/trac/")
        @url = url
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