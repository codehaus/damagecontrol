require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/web/SearchServlet'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'
require 'pebbles/MVCServletTesting'

module DamageControl
  class SearchServletTest < Test::Unit::TestCase
    include FileUtils
    include Pebbles::MVCServletTesting

    def test_search_project
      build_history_repository = MockIt::Mock.new
      build_history_repository.__expect(:search) {|regexp, project_name|
        assert_equal(/search term/i, regexp)
        assert_equal("myprojectname", project_name)
        [Build.new]
      }
      servlet = SearchServlet.new(build_history_repository)
      result = do_request("search"=> "search term", "project_name" => "myprojectname") do
        servlet.default_action
      end
    end

    def test_global_search
      build_history_repository = MockIt::Mock.new
      build_history_repository.__expect(:search) {|regexp, project_name|
        assert_equal(/search term/i, regexp)
        assert_equal(nil, project_name)
        []
      }
      servlet = SearchServlet.new(build_history_repository)
      result = do_request("search"=> "search term") do
        servlet.default_action
      end
    end
    
  end
end