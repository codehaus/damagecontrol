require 'damagecontrol/web/ChangesReport'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/core/Build'
require 'pebbles/MVCServletTesting'
require 'pebbles/mockit'
require 'test/unit'

module DamageControl
  class ChangesReportTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting
    
    def setup
    end

    def mock_project_config_repository(project_config)
      @project_config_repository = MockIt::Mock.new
      @project_config_repository.__setup(:project_exists?) {|p| true }
      @project_config_repository.__setup(:project_config) {|p| project_config }
      @project_config_repository
    end
    
    def test_quoted_message_replaces_jira_keys
      build = Build.new("myprojectname")
      @report = ChangesReport.new(build, mock_project_config_repository({
        "jira_url" => "http://jira.codehaus.org"
      }))
      assert_equal("", @report.quote_message(''))
      assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @report.quote_message('DC-148'))
      assert_equal('xDC-148', @report.quote_message('xDC-148'))
      assert_equal('fixed  <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>.', @report.quote_message('fixed  DC-148.'))
      assert_equal('fixed <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>.', @report.quote_message('fixed DC-148.'))
      assert_equal('blahblah<br/>blah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @report.quote_message("blahblah\nblah\nblah DC-148"))
      assert_equal('blahblah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> blah<br/>blah', @report.quote_message("blahblah\nblah DC-148 blah\nblah"))
      assert_equal('blahblah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> blah<br/>blah', @report.quote_message("blahblah\nblah DC-148 blah\nblah"))
      assert_equal('<a href="http://jira.codehaus.org/browse/DC-150">DC-150</a>', @report.quote_message('DC-150'))
    end
    
  end
end