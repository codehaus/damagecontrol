require 'yaml'
require 'test/unit'
require 'rscm/tempdir'
require 'rscm/changes'
require 'rscm/tracker'
require 'rscm/scm_web'

module RSCM
  class ChangesTest < Test::Unit::TestCase
    
    def setup
      #1
      @change1 = Change.new("path/one",   "jon",   "Fixed CATCH-22", "1.1", Time.utc(2004,7,5,12,0,2))
      @change2 = Change.new("path/two",   "jon",   "Fixed CATCH-22", "1.2", Time.utc(2004,7,5,12,0,4))
      #2
      @change3 = Change.new("path/three", "jon",   "hipp hurra",  "1.3", Time.utc(2004,7,5,12,0,6))
      #3
      @change4 = Change.new("path/four",  "aslak", "hipp hurraX", "1.4", Time.utc(2004,7,5,12,0,8))
      #4
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

      assert_equal(@change2.time, changesets[0].time)
      assert_equal(@change7.time, changesets[-1].time)
    end
    
    def test_can_parse_changesets_from_yaml
      changesets = File.open(File.dirname(__FILE__) + "/changesets.yaml") do |io|
        YAML::load(io)
      end
      assert_equal("rinkrank", changesets[0][1].developer)
      assert_equal("En to\ntre buksa \nned\n", changesets[0][1].message)
    end
    
    def test_reports_timestamp_of_latest_change
      changeset = ChangeSet.new
      changeset << Change.new(nil, nil, nil, nil, Time.utc(2004))
      changeset << Change.new(nil, nil, nil, nil, Time.utc(2005))
      changeset << Change.new(nil, nil, nil, nil, Time.utc(2003))
      assert_equal(Time.utc(2005), changeset.time)
    end

    def test_should_write_file_on_write_rss
      changesets = ChangeSets.new
      changesets.add(@change1)
      changesets.add(@change2)
      changesets.add(@change3)

      rss_file = "#{RSCM.new_temp_dir}/rss.xml"
      assert(!File.exist?(rss_file))
      changesets.write_rss(
        "Mooky",
        rss_file,
        "http://damagecontrol.codehaus.org/", 
        "This feed contains SCM changes for the DamageControl project", 
        Tracker::JIRA.new("http://jira.codehaus.org/", "DC"), 
        SCMWeb::ViewCVS.new("http://cvs.damagecontrol.codehaus.org/")
      )
      assert(File.exist?(rss_file))
    end

    def test_should_write_several_changesets_on_save_and_reload_them
      changesets_dir = "#{RSCM.new_temp_dir}/save_load"

      changesets = ChangeSets.new
      changesets.add(@change1)
      changesets.add(@change2)
      changesets.add(@change3)
      changesets.add(@change4)
      changesets.add(@change5)
      changesets.add(@change6)
      changesets.add(@change7)
      changesets.save(changesets_dir)
      
      latest_id = ChangeSets.latest_id(changesets_dir)
      all_reloaded = ChangeSets.load_upto(changesets_dir, latest_id, 100)
      assert_equal(changesets, all_reloaded)

      some_reloaded = ChangeSets.load_upto(changesets_dir, "20040705120008", 2)
      assert_equal(2, some_reloaded.length)
      assert_equal(@change3, some_reloaded[0][0])
      assert_equal(@change4, some_reloaded[1][0])
    end
  end

end
