require 'test/unit'
require 'mock_with_returns'
require 'damagecontrol/BuildEvents'
require 'damagecontrol/Build'
require 'damagecontrol/Hub'
require 'damagecontrol/publisher/JIRAPublisher'
require 'damagecontrol/template/ShortTextTemplate'
require 'ftools'
require 'cgi'

module DamageControl

  class JIRAPublisherTest < Test::Unit::TestCase
  
    def setup
      @jira_publisher = JIRAPublisher.new(Hub.new, ShortTextTemplate.new, "jira.codehaus.org", "rinkrank", "julenissen")

      def @jira_publisher.post_script(script)
        @script = script
      end
      
      def @jira_publisher.get_posted_script
        @script
      end
    end
  
    def test_jira_issue_is_filed_upon_failing_build_complete_event    
      build = Build.new("test_project", {"jira_project_key" => "DC"})
      build.successful = false
      build.label = "99"
      mod = Modification.new()
      mod.developer = "tirsen"
      build.modification_set <<  mod
      
      @jira_publisher.process_message(BuildCompleteEvent.new(build))
      assert_equal(
    %{
<JiraJelly xmlns:jira="jelly:com.atlassian.jira.jelly.JiraTagLib">
  <jira:Login username="rinkrank" password="julenissen">
    <jira:CreateIssue 
      summary="Fix broken build"
      description="BUILD FAILED test_project 99"
      project-key="DC" 
      assignee="tirsen"
      issue-type="Task"
      priority="Major"
      />
  </jira:Login>
</JiraJelly>
}, @jira_publisher.get_posted_script)
    end
    
  end
end
