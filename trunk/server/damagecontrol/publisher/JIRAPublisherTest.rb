require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/Hub'
require 'damagecontrol/publisher/JIRAPublisher'
require 'ftools'
require 'cgi'

module DamageControl

  class JIRAPublisherTest < Test::Unit::TestCase
  
    def setup
      @jira_publisher = JIRAPublisher.new(Hub.new, "short_text_build_result.erb", "jira.codehaus.org", "rinkrank", "julenissen")

      def @jira_publisher.post_script(script)
        @script = script
      end
      
      def @jira_publisher.get_posted_script
        @script
      end
    end
  
    def test_jira_issue_is_filed_upon_failing_build_complete_event    
      build = Build.new("test_project", Time.now, {"jira_project_key" => "DC"})
      build.status = Build::FAILED
      mod = Change.new()
      mod.developer = "damagecontrol"
      build.modification_set <<  mod
      
      @jira_publisher.process_message(BuildCompleteEvent.new(build))
      assert_equal(
    %{
<JiraJelly xmlns:jira="jelly:com.atlassian.jira.jelly.JiraTagLib">
  <jira:Login username="rinkrank" password="julenissen">
    <jira:CreateIssue 
      summary="Fix broken build"
      description="[test_project] BUILD FAILED"
      project-key="DC" 
      assignee="damagecontrol"
      issue-type="Task"
      priority="Major"
      />
  </jira:Login>
</JiraJelly>
}, @jira_publisher.get_posted_script)
    end
    
  end
end
