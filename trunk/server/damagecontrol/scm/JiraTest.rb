require 'damagecontrol/scm/Jira'
require 'damagecontrol/web/ChangesReport'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/Build'
require 'pebbles/MVCServletTesting'
require 'pebbles/mockit'
require 'test/unit'

module DamageControl
  class JiraTest < Test::Unit::TestCase
    def test_quoted_message_replaces_jira_keys
      jira = Jira.new
      jira.jira_url = "http://jira.codehaus.org"
      assert_equal("", jira.highlight(''))
      assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', jira.highlight('DC-148'))
      assert_equal('x<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', jira.highlight('xDC-148'))
      assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>:bla', jira.highlight('DC-148:bla'))
      assert_equal('fixed <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>.', jira.highlight('fixed DC-148.'))
      assert_equal('blahblah<br/>blah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', jira.highlight("blahblah\nblah\nblah DC-148"))
      assert_equal('ABCABCABCABCABCABCABCABCABCABCABCABC <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> ABCABCABCABCABCABCABCABCABCABCABCABC', jira.highlight("ABCABCABCABCABCABCABCABCABCABCABCABC DC-148 ABCABCABCABCABCABCABCABCABCABCABCABC"))
    end
  end
end