require 'damagecontrol/web/ProjectServlet'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'
require 'pebbles/mockit'
require 'test/unit'

module DamageControl
  class ProjectServletTest < Test::Unit::TestCase
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
      @servlet = ProjectServlet.new(nil, nil, mock_project_config_repository({
        "jira_url" => "http://jira.codehaus.org"
      }), nil, nil)
      do_request("project_name" => "myprojectname") do
        assert_equal("", @servlet.instance_eval("quote_message('')"))
        assert_equal('<a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @servlet.instance_eval("quote_message('DC-148')"))
        assert_equal('blahblah<br/>blah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a>', @servlet.instance_eval("quote_message('blahblah\nblah\nblah DC-148')"))
        assert_equal('blahblah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> blah<br/>blah', @servlet.instance_eval("quote_message('blahblah\nblah DC-148 blah\nblah')"))
        assert_equal('blahblah<br/>blah <a href="http://jira.codehaus.org/browse/DC-148">DC-148</a> blah<br/>blah', @servlet.instance_eval("quote_message('blahblah\nblah DC-148 blah\nblah')"))
        assert_equal('<a href="http://jira.codehaus.org/browse/DC-150">DC-150</a>', @servlet.instance_eval("quote_message('DC-150')"))
      end
    end
    
  end
end