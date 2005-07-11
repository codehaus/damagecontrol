require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Tracker
    class ScarabTest < Test::Unit::TestCase 
      def setup
        @tracker = Scarab.new
        @tracker.baseurl = "http://scarab.org"
        @tracker.module_key = "dc"
      end

      def test_should_not_highlight
        assert_equal('catch #22', @tracker.highlight('catch #22'))
      end

      def test_should_highlight
        assert_equal('catch <a href="http://scarab.org/issues/id/dc22">dc22</a>', @tracker.highlight('catch dc22'))
      end
    end
  end
end