require 'test/unit'
require 'rscm/mockit'
require 'rscm'

module RSCM
  class ProjectTest < Test::Unit::TestCase
    include MockIt
    
    def test_should_write_rss
      p = Project.new
      p.name = "rssproject"
      p.scm = new_mock
      p.scm.__expect(:changesets) do
        cs = new_mock
        cs.__expect(:to_rss) do
          "fake rss"
        end
      end
      p.write_rss

      File.open(p.rss_file) do |io|
        assert_equal("fake rss", io.read)
      end
    end
  end
end