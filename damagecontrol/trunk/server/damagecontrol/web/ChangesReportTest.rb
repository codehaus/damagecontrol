require 'damagecontrol/scm/Jira'
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
    include MockIt
    
    def setup
      build = Build.new("myprojectname")
      jira = Jira.new
      jira.jira_url = "http://jira.codehaus.org/"
      @report = ChangesReport.new(build, mock_project_config_repository({
        "tracking" => jira
      }),
      new_mock)
    end
    
    def mock_project_config_repository(project_config)
      @project_config_repository = new_mock
      @project_config_repository.__setup(:project_exists?) {|p| true }
      @project_config_repository.__setup(:project_config) {|p| project_config }
      @project_config_repository
    end
    
    def test_quoted_message_escapes_special_html_characters
      assert_equal('&lt;&gt;&quot;&amp;', @report.quote_message('<>"&'))
    end
  end
end
