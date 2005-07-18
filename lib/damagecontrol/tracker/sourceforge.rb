module DamageControl
  module Tracker
    class SourceForge < Base
      register self

      def self.identifier_examples
        ["#5", "#239"]
      end

      @@pattern = /#([0-9]+)/

      ann :description => "Project id"
      ann :tip => "The id of the project (group_id). Example: <br/><tt>http://sourceforge.net/tracker/index.php?func=detail&amp;aid=1051927&amp;group_id=<strong>7856</strong>&amp;atid=107856</tt>"
      attr_accessor :group_id

      ann :description => "Tracker id"
      ann :tip => "The id of the tracker (aid). Example: <br/><tt>http://sourceforge.net/tracker/index.php?func=detail&amp;aid=<strong>1051927</strong>&amp;group_id=7856&amp;atid=107856</tt>."
      attr_accessor :tracker_id

      def initialize
        @group_id, @tracker_id = "", ""
      end

      def url
        "http://sourceforge.net/tracker/?group_id=#{group_id}"
      end

      def highlight(message)
        htmlize(message.gsub(@@pattern,"<a href=\"http://sourceforge.net/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>"))
      end
    end

  end
end