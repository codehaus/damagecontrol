require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Tracker
    class BugzillaTest < Test::Unit::TestCase

      def setup
        @tracker = Bugzilla.new
      end

      def test_bugzilla
        @tracker.url = "http://bugzilla.org"
        assert_equal('catch <a href="http://bugzilla.org/show_bug.cgi?id=22">#22</a>', @tracker.highlight('catch #22'))
      end
    end
  end
end