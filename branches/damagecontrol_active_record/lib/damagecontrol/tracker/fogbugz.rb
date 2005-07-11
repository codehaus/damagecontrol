module DamageControl
  module Tracker
    class FogBugz < Base
      register self
      
      def self.identifier_examples
        ["#5", "#239"]
      end
      
      ann :description => "Base URL"
      ann :tip => "The URL of the Scarab installation."
      attr_accessor :url

      def initialize
        @url = "http://try4.fogbugz.com/"
      end

      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(@url)
        if (url)
          htmlize(s.gsub(/#([0-9]+)/, "<a href=\"#{url}default.asp?pg=pgEditBug&command=view&ixBug=\\1\">#\\1</a>"))
        else
          htmlize(s)
        end
      end
    end
  end
end