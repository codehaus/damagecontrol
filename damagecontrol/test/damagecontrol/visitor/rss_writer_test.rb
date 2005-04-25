require 'rss/maker'
require 'rscm/difftool_test'
require 'rscm/file_ext.rb'
require 'rscm/revision_fixture'
require 'damagecontrol/visitor/rss_writer'
require 'damagecontrol/tracker'
require 'damagecontrol/scm_web'

module DamageControl
  module Visitor
    class RssWriterTest < Test::Unit::TestCase
      include RSCM::RevisionFixture

      def test_should_generate_rss
        setup_changes
        revisions = RSCM::Revisions.new
        # we have to set the revisions on the changes so the view_cvs links are correct
        @change1.native_revision_identifier =  "1.1"
        @change2.native_revision_identifier =  "1.2"
        @change3.native_revision_identifier =  "1.3"
        revisions.add(@change1)
        revisions.add(@change2)
        revisions.add(@change3)

        RSS::Maker.make("2.0") do |rss|
          revisions.accept(RssWriter.new(
            rss,
            "Mooky",
            "http://damagecontrol.codehaus.org/", 
            "This feed contains SCM changes for the DamageControl project", 
            DamageControl::Tracker::JIRA.new("http://jira.codehaus.org/", "DC"), 
            DamageControl::SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
          ))
          assert_equal_with_diff(File.open(File.dirname(__FILE__) + "/revisions.rss").read_fix_nl, rss.to_rss.to_s)
        end
      end

    end
  end
end