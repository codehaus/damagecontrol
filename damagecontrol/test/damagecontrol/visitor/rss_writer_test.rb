require 'rss/maker'
require 'rscm/difftool_test'
require 'rscm/file_ext.rb'
require 'rscm/changes_fixture'
require 'damagecontrol/visitor/rss_writer'
require 'damagecontrol/tracker'
require 'damagecontrol/scm_web'

module DamageControl
  module Visitor
    class RssWriterTest < Test::Unit::TestCase
      include RSCM::ChangesFixture

      def test_should_generate_rss
        setup_changes
        changesets = RSCM::ChangeSets.new
        # we have to set the revisions on the changes so the view_cvs links are correct
        @change1.revision = "1.1"
        @change2.revision = "1.2"
        @change3.revision = "1.3"
        changesets.add(@change1)
        changesets.add(@change2)
        changesets.add(@change3)

        RSS::Maker.make("2.0") do |rss|
          changesets.accept(RssWriter.new(
            rss,
            "Mooky",
            "http://damagecontrol.codehaus.org/", 
            "This feed contains SCM changes for the DamageControl project", 
            DamageControl::Tracker::JIRA.new("http://jira.codehaus.org/", "DC"), 
            DamageControl::SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
          ))
          assert_equal_with_diff(File.open(File.dirname(__FILE__) + "/changesets.rss").read_fix_nl, rss.to_rss.to_s)
        end
      end

    end
  end
end