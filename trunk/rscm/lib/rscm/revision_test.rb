require 'yaml'
require 'rscm/revision_fixture'

module RSCM
  class RevisionTest < Test::Unit::TestCase
    include RevisionFixture
    
    def setup
      setup_changes
    end
    
    def test_convert_changes_to_revisions_should_match_user_message_and_timestamp_
      revisions = Revisions.new
      revisions.add(@change1)
      revisions.add(@change2)
      revisions.add(@change3)
      revisions.add(@change4)
      revisions.add(@change5)
      revisions.add(@change6)
      revisions.add(@change7)

      revision_0 = Revision.new
      revision_0 << @change1
      revision_0 << @change2
      
      revision_1 = Revision.new
      revision_1 << @change3

      revision_2 = Revision.new
      revision_2 << @change4

      revision_3 = Revision.new
      revision_3 << @change5
      revision_3 << @change6
      revision_3 << @change7

      assert_equal(4, revisions.length)

      expected_revisions = Revisions.new
      expected_revisions.add(revision_0)
      expected_revisions.add(revision_1)
      expected_revisions.add(revision_2)
      expected_revisions.add(revision_3)

      assert_equal(expected_revisions, revisions)
    end
    
    def test_revisions_can_add_individual_changes_and_group_in_revision_instances
      revisions = Revisions.new
      assert(0, revisions.length)
      
      revisions.add(@change1)
      revisions.add(@change2)
      revisions.add(@change3)
      revisions.add(@change4)
      assert(3, revisions.length)
      
      tjo_bing_revision = revisions[0]
      hipp_hurra_revision = revisions[1]
      hipp_hurraX_revision = revisions[2]
      assert(2, tjo_bing_revision.length)
      assert(1, hipp_hurra_revision.length)
      assert(1, hipp_hurraX_revision.length)

      assert_same(@change1, tjo_bing_revision[0])
      assert_same(@change2, tjo_bing_revision[1])
      assert_same(@change3, hipp_hurra_revision[0])
      assert_same(@change4, hipp_hurraX_revision[0])
    end

    def test_should_sort_by_time
      revisions = Revisions.new
      revisions.add(@change1)
      revisions.add(@change4)
      revisions.add(@change2)
      revisions.add(@change7)
      revisions.add(@change5)
      revisions.add(@change3)
      revisions.add(@change6)
      
      revisions = revisions.sort do |a,b|
        a.time <=> b.time
      end
      assert_equal(4, revisions.length)

      assert_equal(@change2.time, revisions[0].time)
      assert_equal(@change7.time, revisions[-1].time)
    end
    
    def test_can_parse_revisions_from_yaml
      revisions = File.open(File.dirname(__FILE__) + "/revisions.yaml") do |io|
        YAML::load(io)
      end
      assert_equal("rinkrank", revisions[0][1].developer)
      assert_equal("En to\ntre buksa \nned\n", revisions[0][1].message)
    end
    
    def test_reports_timestamp_of_latest_change
      revision = Revision.new
      revision << Change.new(nil, nil, nil, nil, nil, Time.utc(2004))
      revision << Change.new(nil, nil, nil, nil, nil, Time.utc(2005))
      revision << Change.new(nil, nil, nil, nil, nil, Time.utc(2003))
      assert_equal(Time.utc(2005), revision.time)
    end

    def test_should_sort_revisions
      revisions = Revisions.new
      revisions.add(@change1)
      revisions.add(@change4)
      revisions.add(@change2)
      revisions.add(@change7)
      revisions.add(@change5)
      revisions.add(@change3)
      revisions.add(@change6)
      
      cs0 = revisions[0]
      cs1 = revisions[1]
      cs2 = revisions[2]
      cs3 = revisions[3]
      
      reversed = revisions.reverse
      assert_equal(cs0, reversed[3])
      assert_equal(cs1, reversed[2])
      assert_equal(cs2, reversed[1])
      assert_equal(cs3, reversed[0])
    end
  end

end
