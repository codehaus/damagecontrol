require 'rscm/path_converter'
require 'rscm/annotations'

module DamageControl
  module Tracker

    # Simple superclass so we can easily include mixins
    # for all subclasses in one fell swoop.
    class Base #:nodoc:
      @@classes = []
      def self.register(cls) 
        @@classes << cls unless @@classes.index(cls)
      end
      
      def self.classes
        @@classes
      end

      def htmlize(str)
        str.gsub(/\n/, "<br>")
      end
    end

    class None < Base
      register self
    
      def name
        "No Tracker"
      end

      def highlight(s)
        htmlize(s)
      end

      def url
        "#"
      end
    end
    # For bwc only.
    class Null < None
    end


    class Bugzilla < Base
      register self

      ann :description => "Bugzilla URL", :tip => "The URL of the Bugzilla installation."
      attr_accessor :url

      def initialize(url="http://bugzilla.org/")
        @url = url
      end
      
      def name
        "Bugzilla"
      end
      
      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(@url)
        if (url)
          htmlize(s.gsub(/#([0-9]+)/, "<a href=\"#{url}show_bug.cgi?id=\\1\">#\\1</a>"))
        else
          htmlize(s)
        end
      end
    end
    
    class Trac < Base
      register self

      ann :description => "Trac URL", :tip => "The URL of the Trac installation. This URL should include no trailing slash. Example: http://my.trac.home/cgi-bin/trac.cgi"
      attr_accessor :url

      def initialize(url="http://trac.org/")
        @url = url
      end
      
      def name
        "Trac"
      end

      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(@url)
        if (url)
          htmlize(s.gsub(/#([0-9]+)/, "<a href=\"#{url}/ticket/\\1\">#\\1</a>"))
        else
          htmlize(s)
        end
      end
    end

    class JIRA < Base
      register self

      ann :description => "Base URL", :tip => "The base URL of the JIRA installation (not the URL to the specific JIRA project)."
      attr_accessor :baseurl

      ann :description => "Project id", :tip => "The id of the project - example: 'DC'"
      attr_accessor :project_id

      def initialize(baseurl="http://jira.codehaus.org/", project_id="")
        @baseurl, @project_id = baseurl, project_id
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

    class SourceForge < Base
      register self

      PATTERN = /#([0-9]+)/
    
      ann :description => "Project id"
      ann :tip => "The id of the project (group_id). Example: <br><tt>http://sourceforge.net/tracker/index.php?func=detail&amp;aid=1051927&amp;group_id=<strong>7856</strong>&amp;atid=107856</tt>"
      attr_accessor :group_id

      ann :description => "Tracker id"
      ann :tip => "The id of the tracker (aid). Example: <br><tt>http://sourceforge.net/tracker/index.php?func=detail&amp;aid=<strong>1051927</strong>&amp;group_id=7856&amp;atid=107856</tt>."
      attr_accessor :tracker_id

      def initialize(group_id="", tracker_id="")
        @group_id, @tracker_id = group_id, tracker_id
      end

      def name
        "SourceForge"
      end

      def url
        "http://sourceforge.net/tracker/?group_id=#{group_id}"
      end

      def highlight(message)
        htmlize(message.gsub(PATTERN,"<a href=\"http://sourceforge.net/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>"))
      end
    end

    class RubyForge < SourceForge
      register self

      ann :description => "Project id"
      ann :tip => "The id of the project (group_id). Example: <br><tt>http://rubyforge.org/tracker/index.php?func=detail&amp;aid=1120&amp;group_id=<strong>426</strong>&amp;atid=1698</tt>."
      attr_accessor :group_id

      ann :description => "Tracker id"
      ann :tip => "The id of the tracker (aid). Example: <br><tt>http://rubyforge.org/tracker/index.php?func=detail&amp;aid=<strong>1120</strong>&amp;group_id=426&amp;atid=1698</tt>."
      attr_accessor :tracker_id

      def name
        "RubyForge"
      end

      def url
        "http://rubyforge.org/tracker/?group_id=#{group_id}"
      end

      def highlight(message)
        htmlize(message.gsub(PATTERN,"<a href=\"http://rubyforge.org/tracker/index.php?func=detail&aid=\\1&group_id=#{group_id}&atid=#{tracker_id}\">#\\1</a>"))
      end
    end

    class Scarab < Base
      register self

      ann :description => "Base URL", :tip => "The URL of the Scarab installation."
      attr_accessor :baseurl

      ann :description => "Scarab Module", :tip => "The Scarab Module key."
      attr_accessor :module_key

      def initialize(baseurl="http://scarab.org/", module_key="")
        @baseurl, @module_key = baseurl, module_key
      end

      def name
        "Scarab"
      end

      def url
        baseurl
      end

      def highlight(s)
        url = RSCM::PathConverter.ensure_trailing_slash(baseurl)
        if (url)
          htmlize(s.gsub(/(#{module_key}[0-9]+)/, "<a href=\"#{url}issues/id/\\1\">\\1</a>"))
        else
          htmlize(s)
        end
      end
    end

  end
end
