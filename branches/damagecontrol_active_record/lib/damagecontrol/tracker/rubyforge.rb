module DamageControl
  module Tracker
    class RubyForge < SourceForge
      register self

      ann :description => "Project id"
      ann :tip => "The id of the project (group_id). Example: <br/><tt>http://rubyforge.org/tracker/index.php?func=detail&amp;aid=1120&amp;group_id=<strong>426</strong>&amp;atid=1698</tt>."
      attr_accessor :group_id

      ann :description => "Tracker id"
      ann :tip => "The id of the tracker (aid). Example: <br/><tt>http://rubyforge.org/tracker/index.php?func=detail&amp;aid=<strong>1120</strong>&amp;group_id=426&amp;atid=1698</tt>."
      attr_accessor :tracker_id

      def name
        "RubyForge"
      end

      def url
        "http://rubyforge.org/tracker/?group_id=#{group_id}"
      end

      def highlight(message)
        htmlize(message.gsub(PATTERN,"<a href=\"http://rubyforge.org/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>"))
      end
    end

  end
end