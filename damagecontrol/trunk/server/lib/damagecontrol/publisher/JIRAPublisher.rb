require 'erb'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'pebbles/Space'
require 'net/http'
require 'cgi'

module DamageControl

  # See http://www.atlassian.com/software/jira/docs/v2.4/jelly.html
  class JIRAPublisher < Pebbles::Space
  
    def initialize(channel, template, jira_host, jira_user=ENV['JIRA_USER'], jira_password=ENV['JIRA_PASSWORD'])
      super
      channel.add_consumer(self)
      @jira_host = jira_host
      @jira_user = jira_user
      @jira_password = jira_password

      template_dir = "#{File.expand_path(File.dirname(__FILE__))}/../template"
      @template = File.new("#{template_dir}/#{template}").read
    end
  
    def on_message(message)
      if message.is_a? BuildCompleteEvent
        if(Build::FAILED == message.build.status)
          puts "JIRA Publisher go failure message"
          jira_project_key = message.build.config["jira_project_key"]
          if(@jira_user && @jira_password && jira_project_key)
#          assignee = message.build.modification_set[0].developer
            assignee = "damagecontrol"
            build = message.build
            msg = ERB.new(@template).result(binding)
            jelly_script = create_jelly_script("Fix broken build", msg, jira_project_key, assignee)
            puts "Posting JIRA issue"
            post_script(jelly_script)
          end
        end
      end
    end
        
    def create_jelly_script(summary, description, jira_project_key, assignee)
    %{
<JiraJelly xmlns:jira="jelly:com.atlassian.jira.jelly.JiraTagLib">
  <jira:Login username="#{@jira_user}" password="#{@jira_password}">
    <jira:CreateIssue 
      summary="#{summary}"
      description="#{description}"
      project-key="#{jira_project_key}" 
      assignee="#{assignee}"
      issue-type="Task"
      priority="Major"
      />
  </jira:Login>
</JiraJelly>
}
    end
    
    def post_script(jelly_script)
      http = Net::HTTP.new(@jira_host)

      # get a cookie (required in order to log in)
      resp, data = http.get("/login.jsp")
      verify(resp)

      set_cookie = resp["Set-Cookie"]
      semi = set_cookie.index(';')
      cookie = set_cookie[0,semi]

      headers = Hash.new
      headers["Cookie"] = cookie
      headers["Content-Type"] = "application/x-www-form-urlencoded"

      # log in (required in order to post jelly script)
      resp, data = http.post("/login.jsp", "os_username=#{@jira_user}&os_password=#{@jira_password}", headers)
      verify(resp)

      # post jelly script
      form_data = "script=" + CGI.escape(jelly_script)
      resp, data = http.post("/secure/admin/util/JellyRunner.jspa", form_data, headers)
      verify(resp)
    end    

    def verify(resp)
      if(resp.code.to_i != 200)
        raise "Couldn't create JIRA issue. HTTP return code: #{resp.code.to_s}"
      end
    end
  end
end