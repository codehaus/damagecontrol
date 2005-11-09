require File.dirname(__FILE__) + '/../test_helper'

class PromotionLevelTest < Test::Unit::TestCase
  fixtures :promotion_levels

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PromotionLevel,  promotion_levels(:promotion_level_1)
  end
end
