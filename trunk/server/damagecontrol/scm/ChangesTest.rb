require 'damagecontrol/scm/Changes'
require 'test/unit'

module DamageControl
  class ChangesTest < Test::Unit::TestCase
    include ChangeUtils
    
    def setup
      @change1 = Change.new("path/one",   "jon",   "tjo bing",    "1.1", Time.utc(2004,7,5,12,0,2))
      @change2 = Change.new("path/two",   "jon",   "tjo bing",    "1.2", Time.utc(2004,7,5,12,0,4))
      @change3 = Change.new("path/three", "jon",   "hipp hurra",  "1.3", Time.utc(2004,7,5,12,0,6))
      @change4 = Change.new("path/four",  "aslak", "hipp hurraX", "1.4", Time.utc(2004,7,5,12,0,8))
      @change5 = Change.new("path/five",  "aslak", "hipp hurra",  "1.5", Time.utc(2004,7,5,12,0,10))
      @change6 = Change.new("path/six",   "aslak", "hipp hurra",  "1.6", Time.utc(2004,7,5,12,0,12))
      @change7 = Change.new("path/seven", "aslak", "hipp hurra",  "1.7", Time.utc(2004,7,5,12,0,14))

      @all_changes = [@change1, @change2, @change3, @change4, @change5, @change6, @change7]
    end
    
    def test_changes_within_period_should_be_filtered_out
      result = changes_within_period(@all_changes, Time.utc(2004,7,5,12,0,6), Time.utc(2004,7,5,12,0,8))
      assert_equal([@change3, @change4], result)
    end

    def test_convert_changes_to_changesets_should_match_user_message_and_timestamp_
      result = convert_changes_to_changesets(@all_changes)

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

      assert_equal(4, result.size)
      assert_equal([changeset_0, changeset_1, changeset_2, changeset_3], result)
    end
  end
end