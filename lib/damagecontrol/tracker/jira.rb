module DamageControl
  module Tracker
    class Jira < Base
      register self

      def self.identifier_examples
        ["DC-148", "CATCH-22"]
      end

      ann :description => "Base URL"
      ann :tip => "The base URL of the JIRA installation (not the URL to the specific JIRA project)."
      attr_accessor :baseurl

      ann :description => "Project id"
      ann :tip => "The id of the project - example: 'DC'"
      attr_accessor :project_id

      def initialize
        @baseurl = "http://jira.codehaus.org/"
        @project_id = ""
      end

      def name
        "JIRA"
      end

      def url
        "#{RSCM::PathConverter.ensure_trailing_slash(baseurl)}browse/#{project_id}"
      end

      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(baseurl)
        if(url)
          htmlize(s.gsub(/([A-Z]+-[0-9]+)/, "<a href=\"#{url}browse/\\1\">\\1</a>"))
        else
          htmlize(s)
        end
      end
    end

  end
end