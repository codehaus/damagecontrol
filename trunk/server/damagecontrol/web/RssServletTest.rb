require 'test/unit'
require 'rexml/document'
require 'pebbles/mockit'
require 'pebbles/MVCServletTesting'

require 'damagecontrol/core/Build'
require 'damagecontrol/web/RssServlet'

module DamageControl
  class RssServletTest < Test::Unit::TestCase

    include Pebbles::MVCServletTesting

    class FakeBuildHistoryRepository
      
      def initialize(build)
        @build = build
      end

      def last_completed_build(project_name)
        @build
      end

      def to_rss(project_name)
        document = REXML::Document.new()
        document.add_element("rss")
        document        
      end

    end

    def test_rss
      build = Build.new("myproject")
      build.dc_creation_time = Time.utc(2004,10,7,16,0,0)
      build_history_repository = FakeBuildHistoryRepository.new(build)
      servlet = RssServlet.new(build_history_repository, "http://builds.codehaus.org/rss")
      result = do_request("/myproject", {}) do
        servlet.default_action
      end

      assert_equal("<rss/>", result)
    end

    def test_rss_returns_not_modified_when_given_an_etag_with_current_timestamp
      build = Build.new("myproject")
      build.dc_creation_time = Time.utc(2004,10,7,16,0,0)
      build_history_repository = FakeBuildHistoryRepository.new(build)
      servlet = RssServlet.new(build_history_repository, "http://builds.codehaus.org/rss")
      result = do_request("/myproject", {}) do
        Thread.current["request"]["If-None-Match"] = 'W/"20041007160000"'
        servlet.default_action
        assert_equal(WEBrick::HTTPStatus::NotModified.code, Thread.current["response"].status)
      end
      assert_equal("", result)
    end

    def test_rss_returns_content_when_given_an_etag_with_an_old_timestamp
      build = Build.new("myproject")
      build.dc_creation_time = Time.utc(2004,10,7,16,0,0)
      build_history_repository = FakeBuildHistoryRepository.new(build)
      servlet = RssServlet.new(build_history_repository, "http://builds.codehaus.org/rss")
      result = do_request("/myproject", {}) do
        Thread.current["request"]["If-None-Match"] = 'W/"20041004100000"'
        servlet.default_action
        assert_equal('W/"20041007160000"', Thread.current["response"]["ETag"])
      end
      assert_equal("<rss/>", result)
    end

  end
end

