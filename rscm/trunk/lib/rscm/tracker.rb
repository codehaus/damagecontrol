require 'rscm/path_converter'

module RSCM
  module Tracker

    class Bugzilla
      attr_accessor :bugzilla_url

      def initialize(bugzilla_url)
        @bugzilla_url = bugzilla_url
      end

      def url
        bugzilla_url
      end

      def highlight(s)
        url = PathConverter.ensure_trailing_slash(bugzilla_url)
        if (url)
          s.gsub(/#([0-9]+)/, "<a href=\"#{url}show_bug.cgi?id=\\1\">#\\1</a>")
        else
          s
        end
      end
    end

    class JIRA
      attr_accessor :jira_url
      attr_accessor :jira_project_id

      def initialize(jira_url, jira_project_id)
        @jira_url, @jira_project_id = jira_url, jira_project_id
      end

      def url
        "#{PathConverter.ensure_trailing_slash(jira_url)}browse/#{jira_project_id}"
      end

      def highlight(s)
        url = PathConverter.ensure_trailing_slash(jira_url)
        if(url)
          s.gsub(/([A-Z]+-[0-9]+)/, "<a href=\"#{url}browse/\\1\">\\1</a>")
        else
          s
        end
      end
    end

    class RubyForge
      attr_accessor :rf_group_id
      attr_accessor :rf_tracker_id

      def initialize(rf_group_id, rf_tracker_id)
        @rf_group_id, @rf_tracker_id = rf_group_id, rf_tracker_id
      end

      def url
        "http://rubyforge.org/tracker/?group_id=#{rf_group_id}"
      end

      def highlight(message)
        message.gsub(/#([0-9]+)/,"<a href=\"http://rubyforge.org/tracker/index.php?func=detail&aid=\\1&group_id=#{rf_group_id}&atid=#{rf_tracker_id}\">#\\1</a>")
      end
    end

    class SourceForge
      attr_accessor :sf_group_id
      attr_accessor :sf_tracker_id

      def initialize(sf_group_id, sf_tracker_id)
        @sf_group_id, @sf_tracker_id = sf_group_id, sf_tracker_id
      end

      def url
        "http://sourceforge.net/tracker/?group_id=#{sf_group_id}"
      end

      def highlight(message)
        message.gsub(/#([0-9]+)/,"<a href=\"http://sourceforge.net/tracker/index.php?func=detail&aid=\\1&group_id=#{sf_group_id}&atid=#{sf_tracker_id}\">#\\1</a>")
      end
    end

    class Scarab
      attr_accessor :scarab_url
      attr_accessor :scarab_module_key

      def initialize(scarab_url, scarab_module_key)
        @scarab_url, @scarab_module_key = scarab_url, scarab_module_key
      end

      def url
        scarab_url
      end

      def highlight(s)
        url = PathConverter.ensure_trailing_slash(scarab_url)
        if (url)
          s.gsub(/(#{scarab_module_key}[0-9]+)/, "<a href=\"#{url}issues/id/\\1\">\\1</a>")
        else
          s
        end
      end
    end

  end
end
