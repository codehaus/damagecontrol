require 'damagecontrol/scm/Changes'
require 'test/unit'

module DamageControl
  class ChangesTest < Test::Unit::TestCase
    
    def setup
      @change1 = Change.new("path/one",   "jon",   "tjo bing",    "1.1", Time.utc(2004,7,5,12,0,2))
      @change2 = Change.new("path/two",   "jon",   "tjo bing",    "1.2", Time.utc(2004,7,5,12,0,4))
      @change3 = Change.new("path/three", "jon",   "hipp hurra",  "1.3", Time.utc(2004,7,5,12,0,6))
      @change4 = Change.new("path/four",  "aslak", "hipp hurraX", "1.4", Time.utc(2004,7,5,12,0,8))
      @change5 = Change.new("path/five",  "aslak", "hipp hurra",  "1.5", Time.utc(2004,7,5,12,0,10))
      @change6 = Change.new("path/six",   "aslak", "hipp hurra",  "1.6", Time.utc(2004,7,5,12,0,12))
      @change7 = Change.new("path/seven", "aslak", "hipp hurra",  "1.7", Time.utc(2004,7,5,12,0,14))
    end
    
    def test_convert_changes_to_changesets_should_match_user_message_and_timestamp_
      changesets = ChangeSets.new
      changesets.add(@change1)
      changesets.add(@change2)
      changesets.add(@change3)
      changesets.add(@change4)
      changesets.add(@change5)
      changesets.add(@change6)
      changesets.add(@change7)

      changeset_0 = ChangeSet.new
      changeset_0 << @change1
      changeset_0 << @change2
      
      changeset_1 = ChangeSet.new
      changeset_1 << @change3

      changeset_2 = ChangeSet.new
      changeset_2 << @change4

      changeset_3 = ChangeSet.new
      changeset_3 << @change5
      changeset_3 << @change6
      changeset_3 << @change7

      assert_equal(4, changesets.length)

      expected_changesets = ChangeSets.new
      expected_changesets.add(changeset_0)
      expected_changesets.add(changeset_1)
      expected_changesets.add(changeset_2)
      expected_changesets.add(changeset_3)

      assert_equal(expected_changesets, changesets)
    end
    
    def test_changesets_can_add_individual_changes_and_group_in_changeset_instances
      changesets = ChangeSets.new
      assert(0, changesets.length)
      
      changesets.add(@change1)
      changesets.add(@change2)
      changesets.add(@change3)
      changesets.add(@change4)
      assert(3, changesets.length)
      
      tjo_bing_changeset = changesets[0]
      hipp_hurra_changeset = changesets[1]
      hipp_hurraX_changeset = changesets[2]
      assert(2, tjo_bing_changeset.length)
      assert(1, hipp_hurra_changeset.length)
      assert(1, hipp_hurraX_changeset.length)

      assert_same(@change1, tjo_bing_changeset[0])
      assert_same(@change2, tjo_bing_changeset[1])
      assert_same(@change3, hipp_hurra_changeset[0])
      assert_same(@change4, hipp_hurraX_changeset[0])
    end

    def test_format
allsets = <<EOF
MAIN:jon:20040705120002
jon
05 July 2004 12:00:02 UTC (2 minutes ago)
tjo bing
----
path/one 1.1
path/two 1.2

MAIN:jon:20040705120006
jon
05 July 2004 12:00:06 UTC (1 minute ago)
hipp hurra
----
path/three 1.3

MAIN:aslak:20040705120008
aslak
05 July 2004 12:00:08 UTC (1 minute ago)
hipp hurraX
----
path/four 1.4

MAIN:aslak:20040705120010
aslak
05 July 2004 12:00:10 UTC (1 minute ago)
hipp hurra
----
path/five 1.5
path/six 1.6
path/seven 1.7

EOF

      changesets = ChangeSets.new
      changesets.add(@change1)
      changesets.add(@change2)
      changesets.add(@change3)
      changesets.add(@change4)
      changesets.add(@change5)
      changesets.add(@change6)
      changesets.add(@change7)
      assert_equal(allsets, changesets.format(CHANGESET_TEXT_FORMAT, Time.utc(2004,7,5,12,2,2)))
    end

    def test_to_rss_description
      changesets = ChangeSets.new
      @change1.status = Change::ADDED
      changesets.add(@change1)
      changesets.add(@change4)
      description = changesets.to_rss_description
      assert_equal("jon", description.get_text("p[1]/strong").value)
      assert_equal("Added path/one", description.get_text("p[1]/ul/li").value)
      assert_equal("aslak", description.get_text("p[2]/strong").value)      
    end
    
    def test_should_sort_by_time
      changesets = ChangeSets.new
      changesets.add(@change1)
      changesets.add(@change4)
      changesets.add(@change2)
      changesets.add(@change7)
      changesets.add(@change5)
      changesets.add(@change3)
      changesets.add(@change6)
      
      changesets = changesets.sort do |a,b|
        a.time <=> b.time
      end
      assert_equal(4, changesets.length)

      assert_equal(@change1.time, changesets[0].time)
      assert_equal(@change7.time, changesets[-1].time)
    end

  end

end
