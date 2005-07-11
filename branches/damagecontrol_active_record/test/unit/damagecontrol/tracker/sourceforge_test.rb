require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Tracker
    class SourceForgeTest < Test::Unit::TestCase
      
      def setup
        @tracker = SourceForge.new
        @tracker.group_id = "333"
        @tracker.tracker_id = "444"
      end

      def test_source_forge

        assert_equal('catch <a href="http://sourceforge.net/tracker/index.php?func=detail&aid=22&group_id=333&atid=444">#22</a>', @tracker.highlight('catch #22'))
      end
    end
  end
end