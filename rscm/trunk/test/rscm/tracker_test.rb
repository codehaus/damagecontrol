require 'test/unit'
require 'rscm/tracker'

module RSCM
  module Tracker
    class TrackerTest < Test::Unit::TestCase

      def test_bugzilla
        bugzilla = Bugzilla.new
        bugzilla.bugzilla_url = "http://bugzilla.org"
        assert_equal('', bugzilla.highlight(''))
        assert_equal('catch <a href="http://bugzilla.org/show_bug.cgi?id=22">#22</a>', bugzilla.highlight('catch #22'))
      end

      def test_jira
        jira = JIRA.new
        jira.jira_url = "http://jira.codehaus.org"

        assert_equal('', jira.highlight(''))
        assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', jira.highlight('DC-148'))
        assert_equal('x<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', jira.highlight('xDC-148'))
        assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>:bla', jira.highlight('DC-148:bla'))
        assert_equal('fixed <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>.', jira.highlight('fixed DC-148.'))
        assert_equal('Fixed <a href="http://jira.codehaus.org/browse/CATCH-22">CATCH-22</a>', jira.highlight('Fixed CATCH-22'))
        assert_equal('blahblah\nblah\nblah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', jira.highlight('blahblah\nblah\nblah DC-148'))
        assert_equal('ABCABCABCABCABCABCABCABCABCABCABCABC <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> ABCABCABCABCABCABCABCABCABCABCABCABC', jira.highlight('ABCABCABCABCABCABCABCABCABCABCABCABC DC-148 ABCABCABCABCABCABCABCABCABCABCABCABC'))
      end

      def test_ruby_forge
        rf = RubyForge.new
        rf.rf_group_id = "333"
        rf.rf_tracker_id = "444"

        assert_equal('catch <a href="http://rubyforge.org/tracker/index.php?func=detail&aid=22&group_id=333&atid=444">#22</a>', rf.highlight('catch #22'))
      end

      def test_source_forge
        sf = SourceForge.new
        sf.sf_group_id = "333"
        sf.sf_tracker_id = "444"

        assert_equal('catch <a href="http://sourceforge.net/tracker/index.php?func=detail&aid=22&group_id=333&atid=444">#22</a>', sf.highlight('catch #22'))
      end

      def test_scarab
        scarab = Scarab.new
        scarab.scarab_url = "http://scarab.org"
        scarab.scarab_module_key = "dc"

        assert_equal('catch #22', scarab.highlight('catch #22'))
        assert_equal('catch <a href="http://scarab.org/issues/id/dc22">dc22</a>', scarab.highlight('catch dc22'))
      end

    end
  end
end