require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Tracker
    class JiraTest < Test::Unit::TestCase
      def setup
        @tracker = Jira.new
        @tracker.baseurl = "http://jira.codehaus.org"
        @tracker.project_id = "DC"
      end

      def test_jira

        assert_equal('', @tracker.highlight(''))
        assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @tracker.highlight('DC-148'))
        assert_equal('x<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @tracker.highlight('xDC-148'))
        assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>:bla', @tracker.highlight('DC-148:bla'))
        assert_equal('fixed <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>.', @tracker.highlight('fixed DC-148.'))
        assert_equal('Fixed <a href="http://jira.codehaus.org/browse/CATCH-22">CATCH-22</a>', @tracker.highlight('Fixed CATCH-22'))
        assert_equal('blahblah\nblah\nblah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @tracker.highlight('blahblah\nblah\nblah DC-148'))
        assert_equal('ABCABCABCABCABCABCABCABCABCABCABCABC <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> ABCABCABCABCABCABCABCABCABCABCABCABC', @tracker.highlight('ABCABCABCABCABCABCABCABCABCABCABCABC DC-148 ABCABCABCABCABCABCABCABCABCABCABCABC'))
      end

    end
  end
end