require 'test/unit'
require 'rscm/mockit'
require 'rscm'

module RSCM
  class RssServiceTest < Test::Unit::TestCase
    include MockIt
  
    def test_should_not_add_feeds_twice
      s = RssService.new
      s.add_project("a")
      assert_equal(["a"], s.projects)
      s.add_project("a")
      assert_equal(["a"], s.projects)
    end

    def test_should_tell_all_projects_to_write_rss
      p = new_mock
      p.__expect(:write_rss)

      s = RssService.new
      s.add_project(p)
      s.write_rss
    end
    
    def test_should_write_rss_in_a_loop
      p = new_mock
      p.__expect(:write_rss)
      p.__expect(:write_rss)

      s = RssService.new
      s.add_project(p)
      s.start(2)
      sleep 3
      s.stop
    end
  end
end