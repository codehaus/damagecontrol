require 'rscm/file_ext.rb'
require 'rscm/changes_fixture'
require 'rscm/visitor/rss_writer'
require 'rss/maker'
require 'rscm/tracker'
require 'rscm/scm_web'

module RSCM
  module Visitor
    class RssWriterTest < Test::Unit::TestCase

      def test_should_generate_rss
        changesets = RSCM::ChangeSets.new
        changesets.add(@change1)
        changesets.add(@change2)
        changesets.add(@change3)

        RSS::Maker.make("2.0") do |rss|
          changesets.accept(RssWriter.new(
            rss,
            "Mooky",
            "http://damagecontrol.codehaus.org/", 
            "This feed contains SCM changes for the DamageControl project", 
            RSCM::Tracker::JIRA.new("http://jira.codehaus.org/", "DC"), 
            RSCM::SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
          ))
          assert_equal(File.open(File.dirname(__FILE__) + "/changesets.rss").read_fix_nl, rss.to_rss.to_s)
        end
      end

    end
  end
end