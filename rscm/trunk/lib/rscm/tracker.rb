require 'rscm/path_converter'

module RSCM
  module Tracker

    # Simple superclass so we can easily include mixins
    # for all subclasses in one fell swoop.
    class Base #:nodoc:
      def form_file
        basename = $1 if (self.class.name =~ /RSCM::Tracker::(.*)/)
        File.dirname(__FILE__) + "/tracker/#{basename}_form.rhtml"
      end
    end

    class Null < Base
      def name
        "No Tracker"
      end

      def highlight(s)
        s
      end
    end

    class Bugzilla < Base
      attr_accessor :url

      def initialize(url=nil)
        @url = url
      end
      
      def name
        "Bugzilla"
      end

      def highlight(s)
        url = PathConverter.ensure_trailing_slash(url)
        if (url)
          s.gsub(/#([0-9]+)/, "<a href=\"#{url}show_bug.cgi?id=\\1\">#\\1</a>")
        else
          s
        end
      end
    end

    class JIRA < Base
      attr_accessor :baseurl
      attr_accessor :project_id

      def initialize(baseurl=nil, project_id=nil)
        @baseurl, @project_id = baseurl, project_id
      end

      def name
        "JIRA"
      end

      def url
        "#{PathConverter.ensure_trailing_slash(baseurl)}browse/#{project_id}"
      end

      def highlight(s)
        url = PathConverter.ensure_trailing_slash(baseurl)
        if(url)
          s.gsub(/([A-Z]+-[0-9]+)/, "<a href=\"#{url}browse/\\1\">\\1</a>")
        else
          s
        end
      end
    end

    class SourceForge < Base
      PATTERN = /#([0-9]+)/
    
      attr_accessor :group_id
      attr_accessor :tracker_id

      def initialize(group_id=nil, tracker_id=nil)
        @group_id, @tracker_id = group_id, tracker_id
      end

      def name
        "SourceForge"
      end

      def url
        "http://sourceforge.net/tracker/?group_id=#{group_id}"
      end

      def highlight(message)
        message.gsub(PATTERN,"<a href=\"http://sourceforge.net/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>")
      end
    end

    class RubyForge < SourceForge

      # TODO: share the same rhtml template

      def name
        "RubyForge"
      end

      def url
        "http://rubyforge.org/tracker/?group_id=#{group_id}"
      end

      def highlight(message)
        message.gsub(PATTERN,"<a href=\"http://rubyforge.org/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>")
      end
    end

    class Scarab < Base
      attr_accessor :baseurl
      attr_accessor :module_key

      def initialize(baseurl=nil, module_key=nil)
        @baseurl, @module_key = baseurl, module_key
      end

      def name
        "Scarab"
      end

      def url
        baseurl
      end

      def highlight(s)
        url = PathConverter.ensure_trailing_slash(baseurl)
        if (url)
          s.gsub(/(#{module_key}[0-9]+)/, "<a href=\"#{url}issues/id/\\1\">\\1</a>")
        else
          s
        end
      end
    end

  end
end
